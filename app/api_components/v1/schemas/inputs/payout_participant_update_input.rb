# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # The only thing about a participant that can be corrected after they are
      # on the list. Who they are is decided when they are added -- changing
      # that would rewrite whose money the entries against them describe.
      class PayoutParticipantUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            weight: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
