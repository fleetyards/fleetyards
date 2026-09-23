# frozen_string_literal: true

require "discord/new_ship"
require "bsky/post"

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
      return if platform.length(link) > ::Bsky::Post::MAX_LENGTH

      prefix = "New ship added to FleetYards: #{model.manufacturer.name} #{model.name}"
      prefix_budget = ::Bsky::Post::MAX_LENGTH - platform.length(link) - 1
      post = if prefix_budget.positive?
        "#{platform.truncate(prefix, to: prefix_budget)}\n#{link}"
      else
        link
      end

      ::Bsky::Post.new.create(post)
    end
  end
end
