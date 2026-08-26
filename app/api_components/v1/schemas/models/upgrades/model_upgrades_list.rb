# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Upgrades
        class ModelUpgradesList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/ModelUpgrade"}
          })
        end
      end
    end
  end
end
