# frozen_string_literal: true

# The signed-in user's own cart; there is one per user, so no id.
resource :cart, only: %i[show destroy] do
  resources :cart_items, path: "items", only: %i[create update destroy]
end
