# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Which build a blueprint's facts were read from.
      #
      # `retired` on the blueprint says whether that was the build we are on;
      # this says which build it actually was, because live and ptu are loaded
      # separately and a recipe the current build dropped is still rendered off
      # the last one that described it.
      #
      # Named `AdminBlueprintBuild` rather than `BlueprintBuild`: nothing shared
      # carries that name today, but every other blueprint component is emitted
      # into this document from `shared/v1`, and the prefix keeps the admin-only
      # one from colliding the day one is added.
      class AdminBlueprintBuild
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            version: {type: :string},
            environment: {type: :string}
          },
          additionalProperties: false,
          required: %w[version environment]
        })
      end
    end
  end
end
