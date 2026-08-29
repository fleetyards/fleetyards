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
            reason: {type: :string, nullable: true},
            reasonDescription: {type: :string, nullable: true},
            author: ::Admin::V1::Schemas::VersionAuthor,
            changes: {type: :array, items: ::Admin::V1::Schemas::VersionChange},
            createdAt: {type: :string, format: :"date-time", nullable: true}
          },
          required: %w[id itemId itemType event changes]
        })
      end
    end
  end
end
