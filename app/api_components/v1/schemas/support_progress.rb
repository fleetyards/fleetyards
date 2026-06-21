# frozen_string_literal: true

module V1
  module Schemas
    class SupportProgress
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          goal: {
            type: :object,
            properties: {
              amountCents: {type: :integer},
              currency: {type: :string},
              items: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    title: {type: :string},
                    description: {type: :string},
                    amountCents: {type: :integer},
                    currency: {type: :string}
                  },
                  additionalProperties: false,
                  required: %w[title amountCents currency]
                }
              }
            },
            additionalProperties: false,
            required: %w[amountCents currency items]
          },
          monthlyTotal: {
            type: :object,
            properties: {
              amountCents: {type: :integer},
              currency: {type: :string}
            },
            additionalProperties: false,
            required: %w[amountCents currency]
          },
          contributions: {
            type: :array,
            items: {
              type: :object,
              properties: {
                displayName: {type: :string},
                amountCents: {type: :integer},
                currency: {type: :string},
                recurring: {type: :boolean}
              },
              additionalProperties: false,
              required: %w[displayName amountCents currency recurring]
            }
          }
        },
        additionalProperties: false,
        required: %w[monthlyTotal contributions]
      })
    end
  end
end
