class CreateActiveMonitoringMetrics < ActiveRecord::Migration[6.0]
  def change
    create_table :active_monitoring_metrics do |t|
      t.string :name
      t.string :request_id
      t.string :location
      t.string :sql_query
      t.integer :value

      t.timestamps
    end
  end
end
