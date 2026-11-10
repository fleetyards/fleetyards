# frozen_string_literal: true

module V1
  module Schemas
    module Models
      # What a fleetchart lays a ship out from. Its pictures come from the
      # fleetchart views, which are fetched apart from any list.
      class FleetchartModel
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            classification: {type: [:string, :null]},
            classificationLabel: {type: [:string, :null]},
            productionStatus: {type: [:string, :null]},
            manufacturer: {
              type: :object,
              properties: {
                name: {type: :string},
                code: {type: [:string, :null]},
                slug: {type: :string}
              },
              required: %w[name slug]
            },
            metrics: {
              type: :object,
              properties: {
                length: {type: :number},
                beam: {type: :number},
                height: {type: :number},
                fleetchartOffsetLength: {type: :number},
                fleetchartOffsetBeam: {type: :number},
                extendedLength: {type: [:number, :null]},
                extendedBeam: {type: [:number, :null]},
                extendedFleetchartOffsetLength: {type: [:number, :null]},
                extendedFleetchartOffsetBeam: {type: [:number, :null]},
                landedLength: {type: [:number, :null]},
                landedBeam: {type: [:number, :null]},
                landedFleetchartOffsetLength: {type: [:number, :null]},
                landedFleetchartOffsetBeam: {type: [:number, :null]}
              },
              required: %w[length beam height fleetchartOffsetLength fleetchartOffsetBeam]
            }
          },
          required: %w[id name slug manufacturer metrics]
        })
      end
    end
  end
end
