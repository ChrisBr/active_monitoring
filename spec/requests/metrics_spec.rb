require "rails_helper"

RSpec.describe "ActionController metrics", type: :request do
  scenario "is succesful" do
    post books_path

    expect(response).to be_successful
    expect(response.body).to eq("ok")
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

    post books_path

    expect(ActiveMonitoring::Metric.all).to include(
      an_object_having_attributes(
        name: "sql.active_record",
        value: 0,
        created_at: Time.zone.local(2020, 1, 1),
        sql_query: %(INSERT INTO "books" ("name", "created_at", "updated_at") VALUES (?, ?, ?)),
        request_id: response.headers["X-Request-Id"],
        location: "BooksController#create"
      )
    )
  end
end
