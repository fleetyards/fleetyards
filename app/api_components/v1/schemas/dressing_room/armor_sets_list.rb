# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class ArmorSetsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: ::V1::Schemas::DressingRoom::ArmorSet
        })
      end
    end
  end
end
