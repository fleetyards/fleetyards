# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanCount
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              count: {type: :integer}
            },
            additionalProperties: false,
            required: %w[name count]
          })
        end
      end
    end
  end
end
