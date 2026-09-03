# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Changes
        # One fact a patch changed about a ship. `oldValue` is null where the
        # previous build did not carry the fact at all.
        class ModelBuildChange
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              environment: {type: :string},
              fromVersion: {type: :string},
              toVersion: {type: :string},
              field: {type: :string},
              oldValue: {type: [:number, :null]},
              newValue: {type: [:number, :null]},
              recordedAt: {type: :string, format: :"date-time"}
            },
            required: %i[id environment fromVersion toVersion field recordedAt],
            additionalProperties: false
          })
        end
      end
    end
  end
end
