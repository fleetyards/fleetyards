# frozen_string_literal: true

module V1
  module Schemas
    class ScDataDiffBuild
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {environment: {type: :string}, version: {type: :string}},
        additionalProperties: false,
        required: %w[environment version]
      })
    end
  end
end
