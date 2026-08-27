# frozen_string_literal: true

module V1
  module Schemas
    class WeaponIndexItem
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          size: {type: :string},
          manufacturerCode: {type: :string},
          beam: {type: :boolean},
          weaponClass: {type: :string},
          pelletsPerShot: {type: :integer},
          damagePerShot: WeaponIndexDamage
        },
        additionalProperties: false,
        required: %w[id name damagePerShot]
      })
    end
  end
end
