# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyWeaponInHand
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            bones: ::V1::Schemas::DressingRoom::CharacterBodyHandBones,
            helper: ::Shared::V1::Schemas::AttachPoint
          },
          additionalProperties: false,
          required: %w[bones helper]
        })
      end
    end
  end
end
