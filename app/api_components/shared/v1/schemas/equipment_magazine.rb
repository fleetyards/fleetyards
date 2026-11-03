# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentMagazine
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            size: {type: :integer},
            reserve: {type: :integer, description: "Spare magazines a player restocks"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
