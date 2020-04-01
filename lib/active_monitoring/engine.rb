require_relative "core_extensions/action_controller"
module ActiveMonitoring
  class Engine < ::Rails::Engine
    isolate_namespace ActiveMonitoring

    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.prepend(::ActiveMonitoring::CoreExtensions::ActionController::Instrumentation)
    end
  end
end
