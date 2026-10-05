# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class TourCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: [:string, :null]},
            startsAt: {type: [:string, :null], format: "date-time"},
            currency: ::V1::Schemas::Enums::TourCurrencyEnum
          },
          required: %w[title],
          additionalProperties: false
        })
      end
    end
  end
end
