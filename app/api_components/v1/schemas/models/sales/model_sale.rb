# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Sales
        class ModelSale
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              startedAt: {type: :string, format: :"date-time"},
              endedAt: {type: [:string, :null], format: :"date-time"},
              ongoing: {type: :boolean},
              # Null while the sale is still running -- an open stretch has no
              # length to report.
              durationInDays: {type: [:number, :null]}
            },
            required: %i[id startedAt ongoing],
            additionalProperties: false
          })
        end
      end
    end
  end
end
