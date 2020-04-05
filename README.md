# ActiveMonitoring

I gave this talk at [RailsConf 2020 Couch Edition](https://railsconf.com/) and this blog article contains the source code and step by step tutorial.
The talk and tutorial is inspired by my work on [influxdb-rails](https://github.com/influxdata/influxdb-rails) and contains several patterns and learnings from it.

By the end of this tutorial, we will have a very basic Performance Monitoring tool which measures the response and SQL query time of a Rails application.

## Abstract
> Building a Performance Analytics Tool with ActiveSupport

> Setting up a performance analytics tool like NewRelic or Skylight is one of the first things many developers do in a new project. However, have you ever wondered how these tools work under the hood?

> In this talk, we will build a basic performance analytics tool from scratch. We will deep dive into ActiveSupport instrumentations to collect, group and normalise metrics from your app. To persist these metrics, we will use a time series database and visualise the data on a dashboard. By the end of the talk, you will know how your favourite performance analytics tool works.

## Chapter 1: Collecting data
### Notification Framework
As a first step we need to implement a notification framework which we can use to instrument and subscribe to performance metrics.

A basic example of the functionality of our notification framework would be this code:
```ruby
scenario "It can susbcribe and instrument events" do
  events = []
  ActiveMonitoring::Notifications.subscribe("test_event") do |name, start, finish, id, payload|
    events << { name: name, start: start, finish: finish, id: id, payload: payload }
  end

  ActiveMonitoring::Notifications.instrument("test_event", payload: :payload) do
    1 + 1
  end

  expect(metrics[0].name).to eq("test_event")
  expect(metrics[0].payload).to include(payload: :payload)
end
```

The implementation can be found in commit [32c3](https://github.com/ChrisBr/active_monitoring/commit/32c32dcec7529ac7a8e0125b1aaab28cd4219363).
For the sake of simplicity, this framework is not thread safe of course.

This framework is inspired by [ActiveSupport Notifications](https://edgeguides.rubyonrails.org/active_support_instrumentation.html) which already provides various hooks into Rails internals.
The implementatition of Active Support Notifications can be found [here](https://github.com/rails/rails/tree/master/activesupport/lib/active_support/notifications).

### Instrument events
[ActiveSupport Notifications](https://edgeguides.rubyonrails.org/active_support_instrumentation.html) provides already
several hooks to subscribe to e.g. processing of controller actions, SQL queries or view rendering.
However, Rails does not provide hooks for external libraries like Redis or Memcache.
In [ef20](https://github.com/ChrisBr/active_monitoring/commit/ef200ae5bf58f9afd2a69003e2c3620d0d9c86eb) and [46c3](https://github.com/ChrisBr/active_monitoring/commit/46c338f8fa5870bae7dc0e251e637d1d4be551db) we monkey patch Rails
to subscribe to controller actions and SQL queries.

## Chapter 2: Storage
In chapter two we discussed an appropriate storage engine for our data.
Our data would look for example like this

| Timestamp  | Hook | Location | Request ID | Value |
| ------------- | ------------- |------------- |------------- |------------- |
| 01.04.2020 00:31:30 CET | process_action | BooksController#show | cf6d6dcd | 100 ms
| 01.04.2020 00:32:30 CET | sql | BooksController#show | c7c7c841 | 80 ms

This data looks tabular, so using a relational database to store it would make sense.
However, there are several downsides to this approach.

### Relational Database

Relational databases perform very well with applications which map to the basic CRUD operations of the database like a Rails controller.

```ruby
class BooksController < ApplicationController
  def new; end
  def create; end
  def show; end
  def edit; end
  def update; end
  def destroy; end
end
```

However, our plugin does not really use all of these traditional database operations or in a different way we would in a normal Rails app.

#### Create
For each request, we will write one process action and several SQL query data points.
If we extend this application to also cover view render times or background jobs, it's not unlikely we would write 10+ metrics per request.
Depending of how many requests your app does process, we could easily create millions of metrics per year.

#### Read
We will read the metrics in a dashboard for a certain time range like today or last three hours but not randomly.

#### Update
We will almost never go back to update on of the metrics.

#### Delete
We will only delete metrics in batches but not single metrics.
For instance, we are only interested in metrics for the last three months so once a month we can do a 'garbage collection' and delete metrics older than three months.

### Time Series Database

With this all said, a relational database might not be the best storage engine for this kind of data as

* We will heavily write to the database which would cause to frequently create new pages in a [B-Tree](https://en.wikipedia.org/wiki/B-tree) like most relational databases use internally
* We would need to implement some sort of garbage collection to remove old data
* Compression of data would not be very efficient

For this kind of data, a [log based storage engine](https://en.wikipedia.org/wiki/Log-structured_merge-tree) like most [Time Series databases](https://db-engines.com/en/ranking/time+series+dbms) implement it would be more efficient.

However, for the sake of simplicity, we store our metrics in a relational database in this tutorial, the implementation can be found in [5967](https://github.com/ChrisBr/active_monitoring/commit/5967190a1484009476f2378c02e3e0ea96d21624).

## Chapter 3: Cleaning, Normalizing and Grouping
In the previous chapter we already stored the controller metrics.
Before we can store SQL metrics, we need to do some more additional work.

### Cleaning
ActiveRecord does a lot of 'magic' behind the scenes to abstract persisting objects to the database.
Some of this 'magic' requires to execute additional database queries, for instance

* Current version of the database engine
* Which migrations did already run
* Which environment

We're only interested to store application metrics so we need to filter these queries out.
The implementation can be found in [156d](https://github.com/ChrisBr/active_monitoring/commit/156d8f7fb0bd3b013524a20effc65dad05506b3d).

### Normalizing
Depending on the database adapter you use, the queries might contain values.
To group the same queries together, we need to normalize these queries.

```SQL
SELECT * FROM books WHERE id = 1;
SELECT * FROM books WHERE id = 2;
```

For our performance monitoring tool, these two queries should be treated the same and we need to normalize them to
```SQL
SELECT * FROM books WHERE id = xxx;
```

In [66a8](https://github.com/ChrisBr/active_monitoring/commit/66a833a46b40072a8888fb6b6c6bb02ee60bda17) we implement a simple query normalizer.

### Grouping
ActiveRecord is a standalone framework, therefore the payload of the SQL event does not contain a `request_id`.
We can use ActiveRecord for instance in migrations or background jobs so it is perfectly valid to use it outside of a request response cycle.
However, in our Performance Monitoring tool we would like to group requests and SQL queries together so we can see if a query causes a slow response.

Luckily, we also implemented a `start_processing` event in [ef20](https://github.com/ChrisBr/active_monitoring/commit/ef200ae5bf58f9afd2a69003e2c3620d0d9c86eb).
We can now subscribe to this event and set the `request_id` and `location` in a cache which we later read
in when writing the SQL metrics.
In [b1f1](https://github.com/ChrisBr/active_monitoring/commit/b1f1847270935beacc236bc54535ced1eb83c5ef) we implement a `CurrentAttributes` class and eventually write the SQL metrics.

ActiveSupport ships with [CurrentAttributes](https://github.com/rails/rails/blob/157920aead96865e3135f496c09ace607d5620dc/activesupport/lib/active_support/current_attributes.rb) out of the box since Rails 5.

## Chapter 4: Visualization
So we now have several metrics in our data base written which would look something like

| Timestamp  | Hook | Location | Request ID | Value |
| ------------- | ------------- |------------- |------------- |------------- |
| 01.04.2020 00:31:30 CET | process_action | BooksController#show | cf6d6dcd | 100 ms
| 01.04.2020 00:32:30 CET | sql | BooksController#show | c7c7c841 | 80 ms

It would be very hard to spot now problems or discover pattern so eventually we need to visualize our collected data.
In [cfca](https://github.com/ChrisBr/active_monitoring/commit/cfcafd2f4664e6927e7d297a4b7da2e18bdd5205) we implement a dashboard to show percentiles and the slowest queries of our Rails app.
A very good blog article about data visualization for performance metrics from Richard Schneemann can be found [here](https://www.schneems.com/2020/03/17/lies-damned-lies-and-averages-perc50-perc95-explained-for-programmers/).

In a real world application, I would strongly recommend to use a dashboard software like [Grafana](https://github.com/grafana/grafana).

## Summary
Congratulations, we implemented a very basic Performance Monitoring tool in just a few hundred lines of code now.
We deep dived into [ActiveSupport Notifications](https://edgeguides.rubyonrails.org/active_support_instrumentation.html) and hooked into Rails events to write request and SQL query metrics in our data storage.
As data storage, we compared relational databases with time series databases like InfluxDB.
Before we could visualize our data, we needed to clean, normalize and group the metrics.

From here, we can easily add more metrics like [rendering of views](https://edgeguides.rubyonrails.org/active_support_instrumentation.html#action-view), 
[caching](https://edgeguides.rubyonrails.org/active_support_instrumentation.html#active-support) or [background jobs](https://edgeguides.rubyonrails.org/active_support_instrumentation.html#active-job).

As initially mentioned, this tutorial is heavily influenced by our work on https://github.com/influxdata/influxdb-rails.
If this made you curious, we always look for new contributors.

## Further information
* [Profiling and Benchmarking 101 by Nate Berkopec](https://youtu.be/XL51vf-XBTs)
* [Lies, Damned Lies, and Averages: Perc50, Perc95 explained for Programmers by Richard Schneeman](https://www.schneems.com/2020/03/17/lies-damned-lies-and-averages-perc50-perc95-explained-for-programmers/)
* https://github.com/influxdata/influxdb-ruby
* https://github.com/influxdata/influxdb-rails
* https://docs.influxdata.com/influxdb/v1.7/concepts/storage_engine/

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
