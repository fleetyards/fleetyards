# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Changes
        class ModelBuildChangesList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/ModelBuildChange"}
          })
        end
      end
    end
  end
end
