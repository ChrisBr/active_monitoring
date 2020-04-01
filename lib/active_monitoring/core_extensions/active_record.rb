module ActiveMonitoring
  module CoreExtensions
    module ActiveRecord
      module Instrumentation
        def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil)
          ::ActiveMonitoring::Notifications.instrument("sql.active_record", sql: sql, name: name) do
            super
          end
        end
      end
    end
  end
end
