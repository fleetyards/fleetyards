# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # How a ship salvages a hull whole and crates what it gathers. The game
      # keeps all of it on the salvage controller, not on the arm or the intake.
      class ComponentSalvageController
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            salvageController: {type: :boolean},
            heads: {type: :integer},
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
            },
            scrapingResource: {type: :string},
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            signatureIr: {type: :number}
          },
          required: %w[salvageController],
          additionalProperties: false
        })
      end
    end
  end
end
