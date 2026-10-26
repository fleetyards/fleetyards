# frozen_string_literal: true

# The signed-in user's active list; items added from the catalogues go here.
resource :cart, only: %i[show destroy] do
  resources :cart_items, path: "items", only: %i[create update destroy] do
    post :bulk, on: :collection, action: :bulk_create
  end
end

resources :carts, controller: "cart_lists", only: %i[index show create update destroy] do
  delete :items, on: :member, action: :clear
end
