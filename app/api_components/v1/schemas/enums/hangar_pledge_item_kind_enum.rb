# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPledgeItemKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPledgeItem::KINDS,
          "x-enumNames": ::HangarPledgeItem::KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
