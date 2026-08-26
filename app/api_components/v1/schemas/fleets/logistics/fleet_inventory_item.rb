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
              stockSlug: {type: :string},
              category: {type: :string},
              quantity: {type: :number},
              unit: {type: :string},
              entryType: {"$ref": "#/components/schemas/InventoryEntryTypeEnum"},
              quality: {type: :integer, minimum: 0, maximum: 1000},
              notes: {type: :string},
              image: {"$ref": "#/components/schemas/MediaFile"},
              item: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  type: {"$ref": "#/components/schemas/InventoryItemTypeEnum"},
                  name: {type: :string},
                  slug: {type: :string},
                  available: {type: :boolean}
                }
              },
              inventory: {
                type: :object,
                properties: {
                  name: {type: :string},
                  slug: {type: :string}
                }
              },
              member: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              addedBy: {
                type: :object,
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
