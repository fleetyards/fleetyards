# frozen_string_literal: true

module V1
  module Schemas
    class FleetFeaturesList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/FleetFeature"}
      })
    end
  end
end
