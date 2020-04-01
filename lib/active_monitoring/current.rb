require_relative "core_extensions/action_controller"
require_relative "core_extensions/active_record"
require_relative "sql_query"
require_relative "current"

module ActiveMonitoring
  class Current
    class << self
      def request_id
        store[:request_id]
      end

      def request_id=(value)
        store[:request_id] = value
      end

      def location
        store[:location]
      end

      def location=(value)
        store[:location] = value
      end

      def store
        Thread.current[:active_monitoring_store] ||= {}
        Thread.current[:active_monitoring_store]
      end
    end
  end
end
