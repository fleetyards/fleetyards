# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronMemberCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            username: {type: :string}
          },
          required: %w[username],
          additionalProperties: false
        })
      end
    end
  end
end
