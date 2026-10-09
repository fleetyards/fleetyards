# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Activity
        class FleetActivityActor
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              username: {type: :string},
              avatar: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]}
            },
            required: %w[id username avatar]
          })
        end
      end
    end
  end
end
