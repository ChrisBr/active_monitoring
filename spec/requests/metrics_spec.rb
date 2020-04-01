require "rails_helper"

RSpec.describe "ActionController metrics", type: :request do
  scenario "is succesful" do
    post books_path

    expect(response).to be_successful
    expect(response.body).to eq("ok")
  end

  scenario "Instruments start_processing.action_controller" do
    travel_to(Time.zone.local(2020, 1, 1))
    events = []
    ActiveMonitoring::Notifications.subscribe("start_processing.action_controller") do |name, start, finish, id, payload|
      events << { name: name, start: start, finish: finish, id: id, payload: payload }
    end

    post books_path

    expect(events).to include(
      a_hash_including(
        name: "start_processing.action_controller",
        start: Time.zone.local(2020, 1, 1),
        finish: Time.zone.local(2020, 1, 1),
        payload: a_hash_including(
          request_id: response.headers["X-Request-Id"]
        )
      )
    )
  end

  scenario "Instruments process_action.action_controller" do
    travel_to(Time.zone.local(2020, 1, 1))

    post books_path

    expect(ActiveMonitoring::Metric.all).to include(
      an_object_having_attributes(
        name: "process_action.action_controller",
        value: 0,
        created_at: Time.zone.local(2020, 1, 1),
        request_id: response.headers["X-Request-Id"],
        location: "BooksController#create"
      )
    )
  end

  scenario "Instruments sql.active_record" do
    travel_to(Time.zone.local(2020, 1, 1))
    events = []
    ActiveMonitoring::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      events << { name: name, start: start, finish: finish, id: id, payload: payload }
    end

    post books_path

    expect(events).to include(
      a_hash_including(
        name: "sql.active_record",
        start: Time.zone.local(2020, 1, 1),
        finish: Time.zone.local(2020, 1, 1),
        payload: a_hash_including(
          sql: %(INSERT INTO "books" ("name", "created_at", "updated_at") VALUES (?, ?, ?)),
          name: "Book Create"
        )
      )
    )
  end
end
