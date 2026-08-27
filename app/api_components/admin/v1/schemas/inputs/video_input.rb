# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class VideoInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid},
              url: {type: :string},
              videoType: ::Shared::V1::Schemas::Enums::VideoTypeEnum
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
