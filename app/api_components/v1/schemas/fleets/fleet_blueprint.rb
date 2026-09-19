# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A recipe somebody in the fleet holds, and who holds it.
      #
      # The blueprint is nested rather than flattened with the owners beside
      # it: the catalogue's own component is what every blueprint surface
      # renders, and copying its properties into a second shape would leave two
      # definitions of a recipe to keep in step.
      class FleetBlueprint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            blueprint: ::Shared::V1::Schemas::Blueprint,

            # Both, rather than the client counting the array: the names are
            # capped by nothing today, but a fleet of two hundred crafters is
            # the case where they will be.
            ownerCount: {type: :integer},
            owners: {type: :array, items: ::V1::Schemas::Fleets::FleetBlueprintOwner}
          },
          additionalProperties: false,
          required: %w[blueprint ownerCount owners]
        })
      end
    end
  end
end
