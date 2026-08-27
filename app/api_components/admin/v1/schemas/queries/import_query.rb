# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ImportQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              typeEq: ::Admin::V1::Schemas::Enums::ImportTypeEnum,
              typeIn: {type: :array, items: ::Admin::V1::Schemas::Enums::ImportTypeEnum},
              typeNotIn: {type: :array, items: ::Admin::V1::Schemas::Enums::ImportTypeEnum},
              aasmStateEq: ::Admin::V1::Schemas::Enums::ImportStatusEnum,
              aasmStateIn: {type: :array, items: ::Admin::V1::Schemas::Enums::ImportStatusEnum},
              adminUserUsernameIn: {type: :array, items: {type: :string}},
              userUsernameIn: {type: :array, items: {type: :string}},
              includeSystem: {type: :boolean}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
