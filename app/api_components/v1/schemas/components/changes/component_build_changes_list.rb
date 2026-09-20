# frozen_string_literal: true

module V1
  module Schemas
    module Components
      module Changes
        class ComponentBuildChangesList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: {"$ref": "#/components/schemas/ComponentBuildChange"}
          })
        end
      end
    end
  end
end
