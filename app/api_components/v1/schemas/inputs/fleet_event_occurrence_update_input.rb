# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventOccurrenceUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            date: {type: :string, format: :date},
            title: {type: [:string, :null]},
            description: {type: [:string, :null]},
            briefing: {type: [:string, :null]},
            location: {type: [:string, :null]},
            meetupLocation: {type: [:string, :null]},
            scenario: {type: [:string, :null]},
            coverImagePreset: {type: [:string, :null]}
          },
          required: %w[date]
        })
      end
    end
  end
end
