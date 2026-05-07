# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FeatureActorInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              actor_type: {type: :string},
              actor_id: {type: :string}
            },
            additionalProperties: false,
            required: %w[actor_type actor_id]
          })
        end
      end
    end
  end
end
