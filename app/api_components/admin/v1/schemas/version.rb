# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Version
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            itemId: {type: :string, format: :uuid},
            itemType: ::Admin::V1::Schemas::Enums::VersionItemTypeEnum,
            event: {type: :string},
            reason: {type: [:string, :null]},
            reasonDescription: {type: [:string, :null]},
            author: ::Admin::V1::Schemas::VersionAuthor,
            changes: {type: :array, items: ::Admin::V1::Schemas::VersionChange},
            createdAt: {type: [:string, :null], format: :"date-time"}
          },
          required: %w[id itemId itemType event changes]
        })
      end
    end
  end
end
