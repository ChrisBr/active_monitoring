require_relative "sql_tracker"
module ActiveMonitoring
  class SqlQuery
    def initialize(query:, name:)
      @query = query
      @name = name
    end

    def track?
      SqlTracker.new(query: query, name: name).track?
    end

    private

      attr_reader :query, :name
  end
end
