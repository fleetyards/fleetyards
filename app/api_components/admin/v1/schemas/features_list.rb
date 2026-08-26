# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FeaturesList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/Feature"}
        })
      end
    end
  end
end
