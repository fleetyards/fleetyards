# frozen_string_literal: true

json.array! @carts, partial: "api/v1/cart_lists/cart", as: :cart
