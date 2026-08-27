# frozen_string_literal: true

module V1
  module Schemas
    class FleetFeaturesList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: ::V1::Schemas::FleetFeature
      })
    end
  end
end
