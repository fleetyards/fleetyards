# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class GameEventInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              title: {type: :string},
              description: {type: :string},
              location: {type: :string},
              url: {type: :string},
              category: ::Admin::V1::Schemas::Enums::GameEventCategoryEnum,
              startsAt: {type: :string, format: "date-time"},
              endsAt: {type: [:string, :null], format: "date-time"},
              published: {type: :boolean},
              # A signed blob id replaces the picture, null removes it.
              coverImage: {type: [:string, :null]}
            },
            additionalProperties: false,
            required: %w[title startsAt]
          })
        end
      end
    end
  end
end
