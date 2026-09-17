# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BlueprintCostModifier
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: [:string, :null]},
            propertyKey: {type: [:string, :null]},

            # The game's own format string for the figure, e.g. "%+.2f %%".
            unitFormat: {type: [:string, :null]},

            # "linear" scales the stat, "linear_integer_additive" adds to it.
            ramp: ::Shared::V1::Schemas::Enums::BlueprintRampEnum,

            # A stat can ramp piecewise, so one stat may appear more than once
            # with different quality windows.
            startQuality: {type: [:integer, :null]},
            endQuality: {type: [:integer, :null]},
            modifierAtStart: {type: [:number, :null]},
            modifierAtEnd: {type: [:number, :null]}
          },
          additionalProperties: false,
          required: %w[ramp]
        })
      end
    end
  end
end
