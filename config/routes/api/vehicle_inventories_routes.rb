# frozen_string_literal: true

resources :vehicles, only: [] do
  resource :inventory, controller: "vehicle_inventory", only: %i[show destroy] do
    resources :inventory_items, path: "items", controller: "vehicle_inventory_items",
      only: %i[index create update destroy] do
      post :import, on: :collection
    end

    get "stock", to: "vehicle_inventory_stock#index"
    get "stock/:slug", to: "vehicle_inventory_stock#show", as: "stock_item"
    patch "stock/:slug", to: "vehicle_inventory_stock#update"
    delete "stock/:slug", to: "vehicle_inventory_stock#destroy"
  end
end
