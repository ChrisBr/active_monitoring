Rails.application.routes.draw do
  resources :books, only: :create
  mount ActiveMonitoring::Engine => "/active_monitoring"
end
