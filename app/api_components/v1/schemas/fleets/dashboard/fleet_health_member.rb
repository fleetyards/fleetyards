# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Dashboard
        class FleetHealthMember
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              username: {type: :string},
              nickname: {type: [:string, :null]},
              lastActiveAt: {type: [:string, :null], format: "date-time"},
              avatar: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]}
            },
            required: %w[username]
          })
        end
      end
    end
  end
end
