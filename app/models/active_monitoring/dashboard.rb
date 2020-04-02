module ActiveMonitoring
  class Dashboard
    LIMIT = 10

    def initialize(date = Date.current)
      @date = date
    end

    def percentile(value)
      response_metrics.percentile(value)
    end

    def slow_sql_queries
      sql_metrics.order(:value).limit(LIMIT)
    end

    private

      attr_reader :date

      def sql_metrics
        metrics.where(name: "sql.active_record")
      end

      def response_metrics
        metrics.where(name: "process_action.action_controller")
      end

      def metrics
        Metric.where(created_at: date.beginning_of_day..date.end_of_day)
      end
  end
end
