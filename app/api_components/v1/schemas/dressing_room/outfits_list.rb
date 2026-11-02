# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class OutfitsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::DressingRoom::Outfit
        })
      end
    end
  end
end
