# frozen_string_literal: true

module V1
  module Schemas
    class WeaponIndex
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::WeaponIndexItem
      })
    end
  end
end
