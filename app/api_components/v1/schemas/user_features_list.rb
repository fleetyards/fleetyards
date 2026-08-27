# frozen_string_literal: true

module V1
  module Schemas
    class UserFeaturesList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/UserFeature"}
      })
    end
  end
end
