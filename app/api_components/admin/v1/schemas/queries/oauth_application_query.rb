# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class OauthApplicationQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              ownerIdEq: {type: :string, format: :uuid},
              aasmStateEq: {type: :string, enum: %w[pending approved rejected]},
              s: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::OauthApplicationSortEnum
              }, ::Admin::V1::Schemas::Sorts::OauthApplicationSortEnum]},
              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::OauthApplicationSortEnum
              }, ::Admin::V1::Schemas::Sorts::OauthApplicationSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
