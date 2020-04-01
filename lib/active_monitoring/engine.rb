require_relative "core_extensions/action_controller"
require_relative "core_extensions/active_record"
require_relative "sql_query"
require_relative "current"

module ActiveMonitoring
  class Engine < ::Rails::Engine
    isolate_namespace ActiveMonitoring

    ActiveSupport.on_load(:active_record) do
      ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(::ActiveMonitoring::CoreExtensions::ActiveRecord::Instrumentation)
    end

    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.prepend(::ActiveMonitoring::CoreExtensions::ActionController::Instrumentation)

      ActiveMonitoring::Notifications.subscribe("start_processing.action_controller") do |_, _, _, _, payload|
        Current.request_id = payload[:request_id]
        Current.location = "#{payload[:controller]}##{payload[:action]}"
      end

      ActiveMonitoring::Notifications.subscribe("process_action.action_controller") do |name, start, finish, _id, payload|
        Metric.create(
          name: name,
          value: finish - start,
          request_id: payload[:request_id],
          location: "#{payload[:controller]}##{payload[:action]}",
          created_at: finish
        )
      end

      ActiveMonitoring::Notifications.subscribe("sql.active_record") do |name, start, finish, _id, payload|
        if ActiveMonitoring::SqlQuery.new(name: payload[:name], query: payload[:sql]).track?
          Metric.create(
            name: name,
            value: finish - start,
            request_id: Current.request_id,
            sql_query: payload[:sql],
            location: Current.location,
            created_at: finish
          )
        end
      end
    end
  end
end
