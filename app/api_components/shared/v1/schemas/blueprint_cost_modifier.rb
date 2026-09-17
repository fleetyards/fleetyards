# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class BlueprintCostModifier
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, nullable: true},
            propertyKey: {type: :string, nullable: true},

            # The game's own format string for the figure, e.g. "%+.2f %%".
            unitFormat: {type: :string, nullable: true},

            # "linear" scales the stat, "linear_integer_additive" adds to it.
            ramp: {type: :string, enum: ::BlueprintCostModifier::RAMPS},

            # A stat can ramp piecewise, so one stat may appear more than once
            # with different quality windows.
            startQuality: {type: :integer, nullable: true},
            endQuality: {type: :integer, nullable: true},
            modifierAtStart: {type: :number, nullable: true},
            modifierAtEnd: {type: :number, nullable: true}
          },
          additionalProperties: false,
          required: %w[ramp]
        })
      end
    end
  end
end
