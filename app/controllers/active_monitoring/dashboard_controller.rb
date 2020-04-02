require_dependency "active_monitoring/application_controller"

module ActiveMonitoring
  class DashboardController < ApplicationController
    def show
      @dashboard = Dashboard.new
    end
  end
end
