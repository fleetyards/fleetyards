# frozen_string_literal: true

require "discord/new_ship"
require "bsky/post"
require "x_com/post"

module Notifications
  class NewModelJob < Notifications::BaseJob
    HASHTAG = "#starcitizen"

    THUMB_VARIANT = {format: :jpeg, resize_to_limit: [1000, 1000], saver: {quality: 80}}.freeze

    def perform(model_id)
      model = Model.find(model_id)
      return if model.notified? || model.hidden?

      ::Discord::NewShip.new(model:).run
      post_socially(model, ::Announcements::Platform::BLUESKY) { |text| ::Bsky::Post.new.create(text, link_card: link_card(model)) } if ::Bsky::Post.configured?
      post_socially(model, ::Announcements::Platform::X) { |text| ::XCom::Post.new.create(text) } if ::XCom::Post.configured?

      model.update(notified: true)
    end

    # A failed social post is reported rather than raised: the job retries, and
    # a retry would post the Discord message and every platform that did work a
    # second time.
    private def post_socially(model, platform)
      text = social_text(model, platform)
      yield text if text.present?
    rescue => e
      Appsignal.report_error(e)
    end

    # The ship name is what gives way when the post runs long; the link and the
    # hashtag are kept whole or the post is not made at all.
    private def social_text(model, platform)
      fixed = "#{model.frontend_url}\n#{HASHTAG}"
      return unless platform.fits?(fixed)

      prefix = "#{model.manufacturer.name} #{model.name} is now on FleetYards"
      budget = platform.limit - platform.length(fixed) - 1
      text = "#{platform.truncate(prefix, to: budget)}\n#{fixed}"

      platform.fits?(text) ? text : fixed
    end

    private def link_card(model)
      ::Bsky::Post::LinkCard.new(
        uri: model.frontend_url,
        title: "#{model.manufacturer.name} #{model.name}",
        description: model.description.to_s.truncate(300),
        image: thumb(model),
        content_type: "image/jpeg"
      )
    end

    # The card is posted without a picture rather than not at all.
    private def thumb(model)
      return unless model.store_image.attached?

      model.store_image.variant(THUMB_VARIANT).processed.download
    rescue => e
      Appsignal.report_error(e)
      nil
    end
  end
end
