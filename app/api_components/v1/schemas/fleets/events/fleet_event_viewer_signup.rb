# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventViewerSignup
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              status: ::V1::Schemas::Enums::FleetEventSignupStatusEnum,
              occurrenceDate: {type: :string, format: :date}
            },
            required: %w[id status]
          })
        end
      end
    end
  end
end
