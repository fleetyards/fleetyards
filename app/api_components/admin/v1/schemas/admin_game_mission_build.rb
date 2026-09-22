# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Which build a mission row is being answered from.
      class AdminGameMissionBuild
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            environment: {type: :string},
            version: {type: :string},

            # False where the row is rendering off the last build that described
            # it, which is what a mission the current build dropped does.
            current: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[environment version current]
        })
      end
    end
  end
end
