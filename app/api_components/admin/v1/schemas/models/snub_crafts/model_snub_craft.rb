# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module SnubCrafts
          class ModelSnubCraft
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                modelId: {type: :string, format: :uuid},
                snubCraftId: {type: :string, format: :uuid},
                model: {
                  type: :object,
                  properties: {
                    id: {type: :string, format: :uuid},
                    name: {type: :string},
                    slug: {type: :string}
                  },
                  required: %w[id name slug]
                },
                snubCraft: {
                  type: :object,
                  properties: {
                    id: {type: :string, format: :uuid},
                    name: {type: :string},
                    slug: {type: :string}
                  },
                  required: %w[id name slug]
                },
                createdAt: {type: :string, format: "date-time"},
                updatedAt: {type: :string, format: "date-time"}
              },
              additionalProperties: false,
              required: %w[id modelId snubCraftId createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
