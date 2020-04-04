require_relative "sql_tracker"
require_relative "sql_normalizer"

module ActiveMonitoring
  class SqlQuery
    def initialize(query:, name:)
      @query = query
      @name = name
    end

    def track?
      SqlTracker.new(query: query, name: name).track?
    end

    def normalized_query
      SqlNormalizer.new(query: query).to_s
    end

    private

      attr_reader :query, :name
  end
end
