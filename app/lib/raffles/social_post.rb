# frozen_string_literal: true

module Raffles
  # The text a raffle is announced with on social media: posted to Bluesky
  # when it opens, and offered in the admin to copy for X by hand. English,
  # like every post the FleetYards accounts make.
  class SocialPost
    KINDS = %w[start last_day].freeze
    HASHTAG = "#starcitizen"

    # X counts a link as 23 characters whatever its length; counting it in
    # full keeps the copied text inside the limit either way.
    X = ::Announcements::Platform::Graphemes.new(:x, 280)

    def initialize(raffle)
      @raffle = raffle
    end

    # The title is what gives way when the post runs long; the link and the
    # hashtag are kept whole.
    def text(kind, platform)
      fixed = "#{@raffle.frontend_url}\n#{HASHTAG}"
      lead = (kind.to_s == "last_day") ? last_day_lead : start_lead
      budget = platform.limit - platform.length(fixed) - 1
      return fixed if budget <= 0

      "#{platform.truncate(lead, to: budget)}\n#{fixed}"
    end

    def link_card
      image, content_type = thumb

      ::Bsky::Post::LinkCard.new(
        uri: @raffle.frontend_url,
        title: @raffle.title,
        description: MarkdownPlainText.render(@raffle.description).squish.truncate(300),
        image:,
        content_type:
      )
    end

    private def start_lead
      "New raffle on FleetYards: #{@raffle.title}. Enter until #{@raffle.ends_at.utc.strftime("%-d %b %Y")}."
    end

    private def last_day_lead
      "Last day to enter the FleetYards raffle: #{@raffle.title}."
    end

    private def thumb
      image = @raffle.ordered_images.first
      return if image.blank?

      variant = image.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium]).processed
      [variant.download, variant.image.content_type]
    rescue => e
      Appsignal.report_error(e)
      nil
    end
  end
end
