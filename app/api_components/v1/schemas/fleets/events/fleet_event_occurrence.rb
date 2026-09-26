# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventOccurrence
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              date: {type: :string, format: :date},
              startsAt: {type: :string, format: "date-time"},
              excluded: {type: :boolean},
              seriesStart: {type: :boolean}
            },
            required: %w[date startsAt excluded seriesStart]
          })
        end
      end
    end
  end
end
