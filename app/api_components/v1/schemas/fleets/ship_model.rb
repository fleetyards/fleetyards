# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # The trimmed model a ship spot points at. Declared once because a spot can
      # name one model or list several, on a mission and on an event alike — the
      # shape was written out four times before this.
      class ShipModel
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            minCrew: {type: :integer},
            maxCrew: {type: :integer},
            image: ::Shared::V1::Schemas::MediaFile
          },
          required: %w[id name slug]
        })
      end
    end
  end
end
