# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # How much distortion a component soaks up. It shuts down at `maximum`,
      # warns at `warningRatio` of it, and sheds `decayRate` per second once
      # `decayDelay` seconds pass without more. `recoveryRatio` is the share of
      # `maximum` it has to fall below to come back on; 0 means as soon as it
      # drops under the maximum.
      class ComponentDistortion
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maximum: {type: :number},
            warningRatio: {type: :number},
            recoveryRatio: {type: :number},
            decayRate: {type: :number},
            decayDelay: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
