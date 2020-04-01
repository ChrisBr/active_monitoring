require "rails_helper"

describe ActiveMonitoring::Notifications do
  it "can subscribe and instrument to an event" do
    travel_to(Time.zone.local(2020, 1, 1))
    events = []
    ActiveMonitoring::Notifications.subscribe("test_event") do |name, start, finish, id, payload|
      events << { name: name, start: start, finish: finish, id: id, payload: payload }
    end

    ActiveMonitoring::Notifications.instrument("test_event", payload: :payload) do
      1 + 1
    end

    expect(events).to include(
      a_hash_including(
        name: "test_event",
        start: Time.zone.local(2020, 1, 1),
        finish: Time.zone.local(2020, 1, 1),
        payload: a_hash_including(
          payload: :payload
        )
      )
    )
  end
end
