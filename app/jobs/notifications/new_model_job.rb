# frozen_string_literal: true

require "discord/new_ship"
require "bsky/post"

module Notifications
  class NewModelJob < Notifications::BaseJob
    HASHTAG = "#starcitizen"

    def perform(model_id)
      model = Model.find(model_id)
      return if model.notified? || model.hidden?

      ::Discord::NewShip.new(model:).run
      post_socially(model, ::Announcements::Platform::BLUESKY) { |text| ::Bsky::Post.new.create(text, link_card: link_card(model)) } if ::Bsky::Post.configured?

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
      image, content_type = thumb(model)

      ::Bsky::Post::LinkCard.new(
        uri: model.frontend_url,
        title: "#{model.manufacturer.name} #{model.name}",
        description: model.description.to_s.truncate(300),
        image:,
        content_type:
      )
    end

    # The representation every store image already has preprocessed, so the
    # job builds nothing new. The card is posted without a picture rather than
    # not at all.
    private def thumb(model)
      return unless model.store_image.attached?

      variant = model.store_image.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium]).processed
      [variant.download, variant.image.content_type]
    rescue => e
      Appsignal.report_error(e)
      nil
    end
  end
end
