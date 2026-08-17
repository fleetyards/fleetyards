# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class SupporterContributionSourceEnum
          include OpenapiRuby::Components::Base

          SOURCES = ::SupporterContribution.sources.keys.freeze

          schema({
            type: :string,
            enum: SOURCES,
            "x-enumNames": SOURCES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
