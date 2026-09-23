# frozen_string_literal: true

require "discord/new_ship"
require "bsky/post"

module Notifications
  class NewModelJob < Notifications::BaseJob
    HASHTAG = "#starcitizen"

    def perform(model_id)
      model = Model.find(model_id)
      return if model.notified?

      ::Discord::NewShip.new(model:).run
      post_socially(model, ::Announcements::Platform::BLUESKY) { |text| ::Bsky::Post.new.create(text) } if ::Bsky::Post.configured?

      model.update(notified: true)
    end

    private def post_socially(model, platform)
      text = social_text(model, platform)
      yield text if text.present?
    end

    # The ship name is what gives way when the post runs long; the link and the
    # hashtag are kept whole or the post is not made at all.
    private def social_text(model, platform)
      fixed = "#{model.frontend_url}\n#{HASHTAG}"
      return unless platform.fits?(fixed)

      prefix = "New ship added to FleetYards: #{model.manufacturer.name} #{model.name}"
      budget = platform.limit - platform.length(fixed) - 1
      text = "#{platform.truncate(prefix, to: budget)}\n#{fixed}"

      platform.fits?(text) ? text : fixed
    end
  end
end
