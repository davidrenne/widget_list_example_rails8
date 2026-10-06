Rails.application.routes.draw do
  root 'items#index'
  match '/items', to: 'items#index', via: [:get, :post]
  match '/ransack', to: 'items#ransack', via: [:get, :post]
  post '/', to: 'items#index'

  if Rails.env.development? || Rails.env.test?
    match '/administration', to: 'widget_list_examples#administration', via: [:get, :post], as: :administration
  end
end
