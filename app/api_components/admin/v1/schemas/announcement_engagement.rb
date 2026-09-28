# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AnnouncementEngagement
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "Bluesky carries the four counts, Discord its reactions",
          properties: {
            likes: {type: :integer},
            reposts: {type: :integer},
            replies: {type: :integer},
            quotes: {type: :integer},
            reactions: {type: :array, items: ::Admin::V1::Schemas::AnnouncementReaction}
          },
          additionalProperties: false
        })
      end
    end
  end
end
