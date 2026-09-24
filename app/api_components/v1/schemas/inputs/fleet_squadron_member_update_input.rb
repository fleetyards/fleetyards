# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronMemberUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            createdAt: {type: :string, format: :date}
          },
          required: %w[createdAt],
          additionalProperties: false
        })
      end
    end
  end
end
