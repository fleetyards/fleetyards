# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Shared because the admin ModelModule subclasses the public one and
      # inherits the reference to this component.
      class ModelModuleMetrics
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            cargo: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
