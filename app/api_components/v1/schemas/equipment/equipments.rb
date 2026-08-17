# frozen_string_literal: true

module V1
  module Schemas
    module Equipment
      class Equipments < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/Equipment"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
