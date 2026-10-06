# frozen_string_literal: true

module V1
  module Schemas
    # Open pads of one size. The size is fitted from the pad's box, in metres.
    # `atcAssigned` is false where a pilot lands without ATC handing the pad out.
    class LocationPad
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          size: ::V1::Schemas::Enums::LocationFacilitySizeEnum,
          count: {type: :integer},
          atcAssigned: {type: :boolean},
          length: {type: [:number, :null]},
          beam: {type: [:number, :null]},
          height: {type: [:number, :null]}
        },
        additionalProperties: false,
        required: %w[size count atcAssigned length beam height]
      })
    end
  end
end
