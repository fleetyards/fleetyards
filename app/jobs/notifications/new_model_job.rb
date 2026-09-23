# frozen_string_literal: true

require "discord/new_ship"
require "bsky/post"
require "announcements/platform"

module Notifications
  class NewModelJob < Notifications::BaseJob
    def perform(model_id)
      model = Model.find(model_id)
      return if model.notified?

      ::Discord::NewShip.new(model:).run
      post_to_bluesky(model) if ::Bsky::Post.configured?

      model.update(notified: true)
    end

    private def post_to_bluesky(model)
      link = model.frontend_url
      platform = ::Announcements::Platform::BLUESKY
      prefix = "New ship added to FleetYards: #{model.manufacturer.name} #{model.name}"
      prefix = platform.truncate(prefix, to: ::Bsky::Post::MAX_LENGTH - platform.length(link) - 1)

      ::Bsky::Post.new.create("#{prefix}\n#{link}")
    end
  end
end
