# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class SupporterContributionUpdateBulkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              ids: {type: :array, items: {type: :string, format: :uuid}},
              anonymous: {type: :boolean},
              source: ::Admin::V1::Schemas::Enums::NullableSupporterContributionSourceEnum
            },
            additionalProperties: false,
            required: %w[ids],
            description: "Only the attributes present are changed; a null `source` clears it."
          })
        end
      end
    end
  end
end
