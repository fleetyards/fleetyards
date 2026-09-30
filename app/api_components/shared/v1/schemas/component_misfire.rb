# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentMisfire
        include OpenapiRuby::Components::Base

        # The levels at which a component starts to misfire, as fractions of
        # each stat, and the misfire window in seconds.
        schema({
          type: :object,
          properties: {
            heat: {type: :number},
            distortion: {type: :number},
            damage: {type: :number},
            wear: {type: :number},
            minWindow: {type: :number},
            maxWindow: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
