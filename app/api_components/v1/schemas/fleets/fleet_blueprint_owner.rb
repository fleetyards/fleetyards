# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # One member of the fleet who holds a recipe. Not a `FleetMember`: that
      # carries the person's role, their reputation links and their whole
      # membership state, none of which a list of names needs -- and all of
      # which would then be repeated once per owner per row.
      class FleetBlueprintOwner
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            userId: {type: :string, format: :uuid},
            username: {type: :string},

            # What this fleet calls them, where it calls them anything.
            nickname: {type: [:string, :null]},
            avatar: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[userId username]
        })
      end
    end
  end
end
