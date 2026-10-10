# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Dashboard
        class FleetOnlineMember
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              userId: {type: :string, format: :uuid},
              username: {type: :string},
              nickname: {type: [:string, :null]},
              friend: {type: :boolean},
              avatar: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]}
            },
            required: %w[userId username friend]
          })
        end
      end
    end
  end
end
