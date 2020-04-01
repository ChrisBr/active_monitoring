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
    events = []
    ActiveMonitoring::Notifications.subscribe("process_action.action_controller") do |name, start, finish, id, payload|
      events << { name: name, start: start, finish: finish, id: id, payload: payload }
    end

    post books_path

    expect(events).to include(
      a_hash_including(
        name: "process_action.action_controller",
        start: Time.zone.local(2020, 1, 1),
        finish: Time.zone.local(2020, 1, 1),
        payload: a_hash_including(
          request_id: response.headers["X-Request-Id"]
        )
      )
    )
  end
end
