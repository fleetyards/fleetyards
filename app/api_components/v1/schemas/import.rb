# frozen_string_literal: true

module V1
  module Schemas
    class Import
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},

          type: ::V1::Schemas::Enums::ImportTypeEnum,
          status: ::V1::Schemas::Enums::ImportStatusEnum,
          info: {type: :string},

          hangarGroup: ::V1::Schemas::Hangar::Groups::HangarGroup,

          output: {type: :object, additionalProperties: true},

          startedAt: {type: :string, format: "date-time"},
          finishedAt: {type: :string, format: "date-time"},
          failedAt: {type: :string, format: "date-time"},
          cancelledAt: {type: :string, format: "date-time"},

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id type status createdAt updatedAt]
      })
    end
  end
end
