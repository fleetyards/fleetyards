# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class TourUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: [:string, :null]},
            startsAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
