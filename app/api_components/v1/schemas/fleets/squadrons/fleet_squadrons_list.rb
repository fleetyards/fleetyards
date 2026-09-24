# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronsList < ::Shared::V1::Schemas::BaseList
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              items: {type: :array, items: ::V1::Schemas::Fleets::Squadrons::FleetSquadron}
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
