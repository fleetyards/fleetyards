# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class FeedbackQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              aasmStateEq: ::Admin::V1::Schemas::Enums::FeedbackStateEnum,
              featureNameEq: {type: :string},
              featureNamePresent: {type: :boolean},
              messageCont: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
