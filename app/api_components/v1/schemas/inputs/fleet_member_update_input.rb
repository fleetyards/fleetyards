# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetMemberUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nickname: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
