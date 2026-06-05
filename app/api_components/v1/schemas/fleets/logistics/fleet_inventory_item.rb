# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventoryItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              category: {type: :string},
              quantity: {type: :number},
              unit: {type: :string},
              entryType: {type: :string, enum: %w[deposit withdrawal]},
              quality: {type: [:integer, :null], minimum: 0, maximum: 1000},
              notes: {type: [:string, :null]},
              image: {anyOf: [{"$ref": "#/components/schemas/MediaFile"}, {type: :null}]},
              item: {
                type: [:object, :null],
                properties: {
                  id: {type: :string, format: :uuid},
                  type: {type: :string},
                  name: {type: :string}
                }
              },
              inventory: {
                type: [:object, :null],
                properties: {
                  name: {type: :string},
                  slug: {type: :string}
                }
              },
              member: {
                type: [:object, :null],
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              addedBy: {
                type: [:object, :null],
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name category quantity unit entryType createdAt updatedAt]
          })
        end
      end
    end
  end
end
