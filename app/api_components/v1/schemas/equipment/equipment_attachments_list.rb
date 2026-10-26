# frozen_string_literal: true

module V1
  module Schemas
    module Equipment
      class EquipmentAttachmentsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/EquipmentAttachment"}
        })
      end
    end
  end
end
