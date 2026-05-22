# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Loaners
          class ModelLoaner
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                modelId: {type: :string, format: :uuid},
                loanerModelId: {type: :string, format: :uuid},
                hidden: {type: :boolean},
                model: {
                  type: :object,
                  properties: {
                    id: {type: :string, format: :uuid},
                    name: {type: :string},
                    slug: {type: :string}
                  },
                  required: %w[id name slug]
                },
                loanerModel: {
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
              required: %w[id modelId loanerModelId hidden createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
