# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelHardpointInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string, nullable: true},
              source: {type: :string, nullable: true},
              key: {type: :string, nullable: true},
              hardpointType: {type: :string, nullable: true},
              group: {type: :string, nullable: true},
              category: {type: :string, nullable: true},
              subCategory: {type: :string, nullable: true},
              size: {type: :string, nullable: true},
              details: {type: :string, nullable: true},
              mount: {type: :string, nullable: true},
              itemSlots: {type: :integer, nullable: true},
              loadoutIdentifier: {type: :string, nullable: true},
              componentId: {type: :string, format: :uuid, nullable: true},
              modelId: {type: :string, format: :uuid, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
