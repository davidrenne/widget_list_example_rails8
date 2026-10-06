Rails.application.routes.draw do
  root 'items#index'
  match '/items', to: 'items#index', via: [:get, :post]
  match '/ransack', to: 'items#ransack', via: [:get, :post]
  post '/', to: 'items#index'
end
