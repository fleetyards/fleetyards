# frozen_string_literal: true

module V1
  module Schemas
    module Equipment
      class EquipmentAttachment
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # The game's attachment subtype the port takes -- Magazine,
            # IronSight, Barrel, BottomAttachment, or a tool's Utility. Plain
            # strings: CIG adds subtypes between builds.
            portType: {type: :string},
            # Whether the weapon ships with this attachment, or a colourway of it.
            default: {type: :boolean},
            attachment: {"$ref": "#/components/schemas/Equipment"}
          },
          additionalProperties: false,
          required: %w[portType default attachment]
        })
      end
    end
  end
end
