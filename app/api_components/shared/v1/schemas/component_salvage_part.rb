# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The salvage controller's figures as the part they are about carries
      # them: a filler station the crates it packs, a salvage arm the hull work.
      class ComponentSalvagePart
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fieldSupportersRequired: {type: :integer},
            # Radii in metres, times in seconds per metre of radius.
            fracture: {
              type: :object,
              properties: {
                minRadius: {type: :number},
                maxRadius: {type: :number},
                timePerMetre: {type: :number}
              },
              additionalProperties: false
            },
            disintegration: {
              type: :object,
              properties: {
                maxRadius: {type: :number},
                timePerMetre: {type: :number},
                scuPerCubicMetre: {type: :number},
                resource: {type: :string}
              },
              additionalProperties: false
            },
            fieldAlignment: {
              type: :object,
              properties: {
                maxSpeedMultiplier: {type: :number},
                maxYieldMultiplier: {type: :number}
              },
              additionalProperties: false
            },
            # Crate sizes in SCU, the fill time in seconds per SCU.
            crates: {
              type: :object,
              properties: {
                minSize: {type: :integer},
                maxSize: {type: :integer},
                fillTimePerScu: {type: :number}
              },
              additionalProperties: false
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
