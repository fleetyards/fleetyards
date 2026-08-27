# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelHullDoor
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            health: {type: :number}
          },
          required: %w[name health],
          additionalProperties: false

        })
      end
    end
  end
end
