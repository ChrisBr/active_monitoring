ActiveMonitoring::Engine.routes.draw do
  resource :dashboard, controller: :dashboard, only: :show
end
