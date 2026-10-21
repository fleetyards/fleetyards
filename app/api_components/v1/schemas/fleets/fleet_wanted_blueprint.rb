# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A recipe somebody in the fleet is after, and who is after it. The
      # counterpart of `FleetBlueprint`, with the members named for what they
      # are here rather than as owners.
      class FleetWantedBlueprint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            blueprint: ::Shared::V1::Schemas::Blueprint,
            wanterCount: {type: :integer},
            wanters: {type: :array, items: ::V1::Schemas::Fleets::FleetBlueprintOwner}
          },
          additionalProperties: false,
          required: %w[id blueprint wanterCount wanters]
        })
      end
    end
  end
end
