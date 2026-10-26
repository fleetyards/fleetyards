# frozen_string_literal: true

module V1
  module Schemas
    module Equipment
      class EquipmentList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/Equipment"}
        })
      end
    end
  end
end
