# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class AnnouncementInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              title: {type: :string},
              body: {type: :string},
              socialBody: {type: :string},
              link: {type: :string},
              icon: {type: :string},
              status: ::Admin::V1::Schemas::Enums::AnnouncementInputStatusEnum,
              publishAt: {type: :string, format: "date-time"},
              notifyUsers: {type: :boolean},
              postDiscord: {type: :boolean},
              postBluesky: {type: :boolean},
              postX: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[title body]
          })
        end
      end
    end
  end
end
