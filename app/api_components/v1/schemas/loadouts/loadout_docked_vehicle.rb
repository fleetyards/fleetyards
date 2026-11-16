# frozen_string_literal: true

module V1
  module Schemas
    module Loadouts
      # The vehicle a docking port carries, whose own slots sit below the port.
      class LoadoutDockedVehicle
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[name slug]
        })
      end
    end
  end
end
