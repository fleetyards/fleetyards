resources :components, only: [:index] do
  get :weapons, on: :collection
end

namespace :filters do
  resources :components, only: [] do
    get :classes, on: :collection
    get "item-types", to: "components#item_types", on: :collection
  end
end
