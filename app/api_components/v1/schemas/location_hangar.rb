# frozen_string_literal: true

module V1
  module Schemas
    # Hangar doors of one size. Each is instanced per player, so the count says
    # how many doors there are, not how many ships fit. The box is the pad
    # inside, in metres: the game's Small hangar holds an extra small pad.
    class LocationHangar
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          size: ::V1::Schemas::Enums::LocationFacilitySizeEnum,
          door: {type: [:string, :null]},
          count: {type: :integer},
          length: {type: [:number, :null]},
          beam: {type: [:number, :null]},
          height: {type: [:number, :null]}
        },
        additionalProperties: false,
        required: %w[size door count length beam height]
      })
    end
  end
end
