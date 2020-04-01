require_relative "core_extensions/action_controller"
require_relative "core_extensions/active_record"

module ActiveMonitoring
  class Engine < ::Rails::Engine
    isolate_namespace ActiveMonitoring

    ActiveSupport.on_load(:active_record) do
      ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(::ActiveMonitoring::CoreExtensions::ActiveRecord::Instrumentation)
    end

    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.prepend(::ActiveMonitoring::CoreExtensions::ActionController::Instrumentation)

      ActiveMonitoring::Notifications.subscribe("process_action.action_controller") do |name, start, finish, _id, payload|
        Metric.create(
          name: name,
          value: finish - start,
          request_id: payload[:request_id],
          location: "#{payload[:controller]}##{payload[:action]}",
          created_at: finish
        )
      end
    end
  end
end
