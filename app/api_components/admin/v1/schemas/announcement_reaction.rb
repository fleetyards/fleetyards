# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AnnouncementReaction
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            emoji: {type: :string, description: "The unicode emoji, or a custom emoji's name"},
            id: {type: :string, description: "Set for a custom emoji"},
            count: {type: :integer}
          },
          additionalProperties: false,
          required: %w[emoji count]
        })
      end
    end
  end
end
