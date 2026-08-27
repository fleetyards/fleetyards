# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class ModelsList
        include OpenapiRuby::Components::Base

        # Models is the paginated collection; this is the bare array the embed,
        # latest and snub-craft endpoints return.

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/Model"}
        })
      end
    end
  end
end
