# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventOccurrenceDateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {date: {type: :string, format: :date}},
          required: %w[date]
        })
      end
    end
  end
end
