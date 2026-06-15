# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MissionTeamUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
