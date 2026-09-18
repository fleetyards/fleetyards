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
            modifierAtEnd: {type: [:number, :null]},

            # The unit the stat is measured in, lifted out of unitFormat.
            unit: {type: [:string, :null]},

            # What the factor applies to: the crafted item's own figure for
            # this stat, which is its value at quality 500. Null where the
            # catalogue holds no such figure -- component health and weapon
            # recoil among them -- and the factor is all there is to show.
            baseValue: {type: [:number, :null]}
          },
          additionalProperties: false,
          required: %w[ramp]
        })
      end
    end
  end
end
