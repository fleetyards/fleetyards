# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ComponentInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              componentClass: {type: :string},
              componentType: {type: :string},
              componentSubType: {type: :string},
              size: {type: :string},
              grade: {type: :string},
              itemClass: {type: :integer},
              itemType: {type: :string},
              manufacturerId: {type: :string, format: :uuid},
              description: {type: :string},
              hidden: {type: :boolean},
              storeImage: {type: :string},
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
