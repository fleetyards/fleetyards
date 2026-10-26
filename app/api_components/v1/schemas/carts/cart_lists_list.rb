# frozen_string_literal: true

module V1
  module Schemas
    module Carts
      class CartListsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::Carts::CartList
        })
      end
    end
  end
end
