# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class BuybackPledgeKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::BuybackPledge::KINDS,
          "x-enumNames": ::BuybackPledge::KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
