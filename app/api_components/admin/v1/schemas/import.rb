# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Import
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},

            type: ::Admin::V1::Schemas::Enums::ImportTypeEnum,
            status: ::Admin::V1::Schemas::Enums::ImportStatusEnum,
            info: {type: :string},
            version: {type: :string},

            input: {type: :object, additionalProperties: true},
            output: {type: :object, additionalProperties: true},
            import: {type: :string},
            importData: {type: :string},

            adminUser: ::Shared::V1::Schemas::UserRefRequired,
            user: ::Shared::V1::Schemas::UserRefRequired,

            startedAt: {type: :string, format: "date-time"},
            finishedAt: {type: :string, format: "date-time"},
            failedAt: {type: :string, format: "date-time"},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id type status createdAt updatedAt]
        })
      end
    end
  end
end
