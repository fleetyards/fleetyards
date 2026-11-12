# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Where on a ship its landing services apply. The game names none of
      # these areas, so `name` is what an admin called it, or null.
      class ServicingArea
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            key: {type: :string},
            name: {type: [:string, :null]},
            width: {type: :number},
            length: {type: :number},
            height: {type: :number}
          },
          additionalProperties: false,
          required: %w[key width length height]
        })
      end
    end
  end
end
