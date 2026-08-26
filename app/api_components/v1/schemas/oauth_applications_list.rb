# frozen_string_literal: true

module V1
  module Schemas
    class OauthApplicationsList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/OauthApplication"}
      })
    end
  end
end
