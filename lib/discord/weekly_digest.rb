# frozen_string_literal: true

require "discord/event_announcement"
require "discord/event_availability"
require "discord/message_length"

module Discord
  # The coming week's events, one list per place they may be announced.
  #
  # The fleet's channel lists what the whole fleet may see, the officers'
  # channel what only officers may, and each squadron channel the events held
  # to that squadron -- the same split as every other announcement, so a digest
  # never shows an event to people it is kept from. A channel with nothing in the week is left alone.
  class WeeklyDigest
    WINDOW = 7.days

    # A draft is not published and a cancelled or completed event is not
    # coming up.
    LISTED_STATUSES = %w[open locked active].freeze

    # A busy week is shortened to what fits in one message and sends the rest
    # to the events page instead.
    MAX_LENGTH = MessageLength::MAX

    def initialize(fleet, from: Time.current)
      @fleet = fleet
      @from = from
      @to = from + WINDOW
    end

    # Queued without its text: each channel's list is built when that post
    # runs, so an event cancelled or narrowed while it waited is not listed.
    def run
      listings.each_key { |target| EventAnnouncement.enqueue(@fleet, target, nil, digest: true) }
    end

    # Only the one channel's entries are looked up in full: slot counts and
    # occurrence overrides are the expensive part, and a fleet with many
    # squadron channels would otherwise pay for all of them once per channel.
    def content_for_target(target)
      entries = detailed(listings[target].to_a)
      entries.any? ? content_for(entries) : nil
    end

    # [[target, content], ...]
    def deliveries
      listings.filter_map do |target, listed|
        entries = detailed(listed)
        [target, content_for(entries)] if entries.any?
      end
    end

    # Each target with the occurrences it may list, before anything about them
    # is looked up.
    private def listings
      @listings ||= begin
        grouped = occurrences.group_by do |occurrence|
          event = occurrence[:event]
          if event.squadron_restricted? then :squadron
          elsif event.officers_only? then :officers
          else :fleet
          end
        end

        result = {}
        EventAnnouncement.fleet_targets(@fleet).each { |target| result[target] = grouped[:fleet] } if grouped[:fleet].present?
        EventAnnouncement.officers_targets(@fleet).each { |target| result[target] = grouped[:officers] } if grouped[:officers].present?

        if ApiClient.configured? && @fleet.fleet_notification_setting&.discord_guild_id.present?
          by_channel(grouped[:squadron].to_a).each do |channel_id, listed|
            result[AnnouncementTarget.squadron(channel_id)] = listed
          end
        end

        result
      end
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
        # A day early: the scope compares a series' last date with the UTC
        # date, which is a day ahead of fleets west of it in their evening.
        # The occurrences themselves are cut to the window below.
        .starting_after(@from - 1.day)
        .where(status: LISTED_STATUSES)
        .includes(:fleet_squadrons)
        .flat_map { |event| event.occurrences(from: @from, to: @to).map { |time| {event: event, time: time} } }
        .sort_by { |occurrence| occurrence[:time] }
    end

    # The start is the occurrence's own instant, the one the window was cut
    # on and the event page shows, so the list and the site cannot disagree.
    # The date is the key occurrence overrides are stored under.
    private def detailed(listed)
      listed.filter_map do |occurrence|
        event = occurrence[:event]
        date = event.recurring? ? occurrence[:time].to_date : nil
        availability = EventAvailability.new(event, occurrence_date: date)
        next if availability.cancelled?

        {event: event, date: date, starts_at: occurrence[:time], title: availability.title, availability: availability.label}
      end
    end

    private def content_for(listed)
      heading = I18n.t("discord.weekly_digest.heading", fleet: @fleet.name)
      lines = listed.map { |occurrence| line_for(occurrence) }

      full = [heading, *lines].join("\n")
      return full if MessageLength.fits?(full)

      # Drop events from the end until what is left fits beside a footer
      # counting exactly the ones dropped.
      shown = lines.size
      loop do
        shown -= 1
        more = I18n.t("discord.weekly_digest.more", count: lines.size - shown, url: url_for_path("/fleets/#{@fleet.slug}/events/"))
        content = [heading, *lines.first(shown), more].join("\n")
        return content if MessageLength.fits?(content) || shown.zero?
      end
    end

    # Discord renders <t:unix:f> in each reader's own timezone.
    private def line_for(occurrence)
      [
        "• [#{occurrence[:title]}](#{event_url(occurrence[:event], occurrence[:date])})",
        "<t:#{occurrence[:starts_at].to_i}:f>",
        occurrence[:availability]
      ].compact_blank.join(" — ")
    end

    # A recurring entry opens its own date; the page reads it from `occurrence`.
    private def event_url(event, date)
      path = "/fleets/#{@fleet.slug}/events/#{event.slug}/"
      path += "?occurrence=#{date.iso8601}" if date

      url_for_path(path)
    end

    private def url_for_path(path)
      "https://#{Rails.configuration.app.domain}#{path}"
    end
  end
end
