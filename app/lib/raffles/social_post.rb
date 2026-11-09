# frozen_string_literal: true

module Raffles
  # The text a raffle is announced with on social media: posted to Bluesky
  # when it opens, on its last day and once it is drawn, and offered in the
  # admin to copy for X by hand. English, like every post the FleetYards
  # accounts make.
  class SocialPost
    KINDS = %w[start last_day drawn].freeze
    HASHTAG = "#starcitizen"

    # X counts a link as 23 characters whatever its length; counting it in
    # full keeps the copied text inside the limit either way.
    X = ::Announcements::Platform::Graphemes.new(:x, 280)

    # A caller that already holds the winner or the entry count passes it in,
    # so a list of raffles queries neither once per row.
    def initialize(raffle, winner: nil, entries_count: nil)
      @raffle = raffle
      @winner = winner
      @entries_count = entries_count
    end

    # The title is what gives way when the post runs long; the link and the
    # hashtag are kept whole. Nil for the drawn post while there is no winner
    # to name.
    def text(kind, platform)
      return if kind.to_s == "drawn" && winner.blank?

      fixed = "#{@raffle.frontend_url}\n#{HASHTAG}"
      lead = case kind.to_s
      when "last_day" then last_day_lead
      when "drawn" then drawn_lead
      else start_lead
      end
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

    # Names the winner the raffle page already shows publicly.
    private def drawn_lead
      "Thank you to all #{@entries_count || @raffle.entries.count} citizens who joined, and better luck next time! " \
        "Congratulations to #{winner.display_username}, the winner of the FleetYards raffle: #{@raffle.title}"
    end

    private def winner
      @winner ||= @raffle.current_winner if @raffle.drawn?
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
