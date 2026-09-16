# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class SupporterContributionLinkedViaEnum
          include OpenapiRuby::Components::Base

          RULES = ::SupporterContribution::LINK_RULES

          schema({
            type: :string,
            enum: RULES,
            "x-enumNames": RULES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
