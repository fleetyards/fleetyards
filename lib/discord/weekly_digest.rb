# frozen_string_literal: true

require "discord/event_announcement"
require "discord/event_availability"

module Discord
  # The coming week's events, one list per place they may be announced.
  #
  # The fleet's channel lists what the whole fleet may see, and each squadron
  # channel lists the events held to that squadron -- the same split as every
  # other announcement, so a digest never shows a squadron's event to the rest
  # of the fleet. A channel with nothing in the week is left alone.
  class WeeklyDigest
    WINDOW = 7.days

    # A draft is not published and a cancelled or completed event is not
    # coming up.
    LISTED_STATUSES = %w[open locked active].freeze

    # Discord cuts a message at 2000 characters; a busy week is shortened and
    # sends the rest to the events page instead.
    MAX_LENGTH = 2000

    def initialize(fleet, from: Time.current)
      @fleet = fleet
      @from = from
      @to = from + WINDOW
    end

    def run
      deliveries.each { |target, content| EventAnnouncement.enqueue(@fleet, target, content) }
    end

    # [[target, content], ...]
    def deliveries
      fleet_occurrences, squadron_occurrences = occurrences.partition { |occurrence| !occurrence[:event].squadron_restricted? }

      result = []

      if fleet_occurrences.any?
        EventAnnouncement.fleet_targets(@fleet).each { |target| result << [target, content_for(fleet_occurrences)] }
      end

      return result unless ApiClient.configured?
      return result if @fleet.fleet_notification_setting&.discord_guild_id.blank?

      by_channel(squadron_occurrences).each do |channel_id, listed|
        result << [AnnouncementTarget.squadron(channel_id), content_for(listed)]
      end

      result
    end

    private def by_channel(squadron_occurrences)
      squadron_occurrences.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |occurrence, channels|
        occurrence[:event].fleet_squadrons.filter_map(&:discord_channel_id).uniq.each do |channel_id|
          channels[channel_id] << occurrence
        end
      end
    end

    private def occurrences
      @occurrences ||= @fleet.fleet_events
        .active_status
        .starting_after(@from)
        .where(status: LISTED_STATUSES)
        .includes(:fleet_squadrons)
        .flat_map { |event| occurrences_of(event) }
        .sort_by { |occurrence| occurrence[:starts_at] }
    end

    private def occurrences_of(event)
      event.occurrences(from: @from, to: @to).filter_map do |time|
        date = event.recurring? ? time.to_date : nil
        availability = EventAvailability.new(event, occurrence_date: date)
        next if availability.cancelled?

        {event: event, starts_at: availability.starts_at, title: availability.title, availability: availability.label}
      end
    end

    private def content_for(listed)
      heading = I18n.t("discord.weekly_digest.heading", fleet: @fleet.name)
      lines = listed.map { |occurrence| line_for(occurrence) }

      full = [heading, *lines].join("\n")
      return full if full.length <= MAX_LENGTH

      # Drop events from the end until what is left fits beside a footer
      # counting exactly the ones dropped.
      shown = lines.size
      loop do
        shown -= 1
        more = I18n.t("discord.weekly_digest.more", count: lines.size - shown, url: url_for_path("/fleets/#{@fleet.slug}/events/"))
        content = [heading, *lines.first(shown), more].join("\n")
        return content if content.length <= MAX_LENGTH || shown.zero?
      end
    end

    # Discord renders <t:unix:f> in each reader's own timezone.
    private def line_for(occurrence)
      [
        "• [#{occurrence[:title]}](#{event_url(occurrence[:event])})",
        "<t:#{occurrence[:starts_at].to_i}:f>",
        occurrence[:availability]
      ].compact_blank.join(" — ")
    end

    private def event_url(event)
      url_for_path("/fleets/#{@fleet.slug}/events/#{event.slug}/")
    end

    private def url_for_path(path)
      "https://#{Rails.configuration.app.domain}#{path}"
    end
  end
end
