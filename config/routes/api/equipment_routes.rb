resources :equipment, only: [:index]

namespace :filters do
  resources :equipment, only: [] do
    get :types, on: :collection
    get "item-types", to: "equipment#item_types", on: :collection
  end
end
