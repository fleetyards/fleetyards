# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyEnvironment
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "The studio the figure is lit in: an environment map, with `lighting` its one key light",
          properties: {
            map: {type: :string, format: :uri, description: "Equirectangular Radiance HDR, linear radiance in three.js light units"},
            intensity: {type: :number, description: "scene.environmentIntensity"},
            exposure: {type: :number, description: "toneMappingExposure, with NeutralToneMapping"}
          },
          additionalProperties: false,
          required: %w[map intensity exposure]
        })
      end
    end
  end
end
