# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CartListUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1, maxLength: 64},
            # Only `true` does anything: another list becoming active is what
            # deactivates this one.
            active: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
