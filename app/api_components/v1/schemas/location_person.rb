# frozen_string_literal: true

module V1
  module Schemas
    # One of the reader's friends or fleet mates at a place, and how the reader
    # knows them: a friend, a fleet they share, or both.
    class LocationPerson
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          username: {type: :string},
          avatar: ::Shared::V1::Schemas::MediaFile,
          # Absent when the reader is not entitled to an answer.
          online: {type: :boolean},
          # Where exactly: the place itself or one inside it.
          currentLocation: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
          friend: {type: :boolean},
          fleets: {type: :array, items: ::V1::Schemas::FleetRef}
        },
        additionalProperties: false,
        required: %w[id username currentLocation friend fleets]
      })
    end
  end
end
