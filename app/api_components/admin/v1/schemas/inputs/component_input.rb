# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ComponentInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              category: {type: :string},
              componentType: ::Shared::V1::Schemas::Enums::ComponentTypeEnum,
              componentSubType: {type: :string},
              size: {type: :string},
              grade: {type: :string},
              itemClass: {type: :integer},
              manufacturerId: {type: :string, format: :uuid},
              description: {type: :string},
              hidden: {type: :boolean},
              storeImage: {type: [:string, :null]},
              scIdentifier: {type: :string},
              scKey: {type: :string},
              scRef: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
