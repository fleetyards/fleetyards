# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Activity
        class FleetActivitiesList
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              items: {
                type: :array,
                items: ::V1::Schemas::Fleets::Activity::FleetActivity
              }
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
