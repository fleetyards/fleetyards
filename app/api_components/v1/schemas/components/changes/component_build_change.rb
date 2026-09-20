# frozen_string_literal: true

module V1
  module Schemas
    module Components
      module Changes
        # One fact a patch changed about a component. `oldValue` is null where
        # the previous build did not carry the fact at all, and `newValue` is
        # null where this one stopped carrying it.
        #
        # Both are strings: a component's facts are names, sizes and grades as
        # well as the numbers inside `typeData`, and one column has to hold all
        # of them.
        #
        # `metric` says which of the two a row is. False is a build fact --
        # `size`, `grade`, `category` -- and true is a figure out of `typeData`,
        # where `field` is the key that payload spells it under.
        class ComponentBuildChange
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              environment: {type: :string},
              fromVersion: {type: :string},
              toVersion: {type: :string},
              field: {type: :string},
              metric: {type: :boolean},
              oldValue: {type: [:string, :null]},
              newValue: {type: [:string, :null]},
              recordedAt: {type: :string, format: :"date-time"}
            },
            required: %i[id environment fromVersion toVersion field metric recordedAt],
            additionalProperties: false
          })
        end
      end
    end
  end
end
