module ActiveMonitoring
  module CoreExtensions
    module ActionController
      module Instrumentation
        def process_action(*)
          payload = {
            controller: self.class.name,
            action: action_name,
            request_id: request.uuid
          }
          ::ActiveMonitoring::Notifications.instrument("start_processing.action_controller", payload)
          ::ActiveMonitoring::Notifications.instrument("process_action.action_controller", payload) do
            super
          end
        end
      end
    end
  end
end
