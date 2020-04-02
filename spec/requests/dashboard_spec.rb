require "rails_helper"

RSpec.describe "ActiveMonitoring Dashboard", type: :request do
  scenario "renders percentile" do
    create_metrics("process_action.action_controller", 10)

    get active_monitoring.dashboard_path

    expect(response.body).to include("90th Percentile: 9")
    expect(response.body).to include("50th Percentile: 5")
  end

  scenario "renders percentile" do
    ActiveMonitoring::Metric.create!(
      value: 100,
      name: "sql.active_record",
      sql_query: "SELECT * FROM books;",
      location: "BooksController#show"
    )

    get active_monitoring.dashboard_path

    expect(response.body).to include("SELECT * FROM books;")
    expect(response.body).to include("BooksController#show")
    expect(response.body).to include("100")
  end

  private

    def create_metrics(name, count)
      1.upto(count) do |i|
        ActiveMonitoring::Metric.create!(value: i, name: name)
      end
    end
end
