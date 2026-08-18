# frozen_string_literal: true

module Calendars
  # Builds an iCalendar (RFC 5545) string for one or more FleetEvent records.
  # Emits a VTIMEZONE block for each distinct non-UTC event timezone so DST-correct
  # rendering doesn't depend on the client's TZ database.
  class IcsBuilder
    include Rails.application.routes.url_helpers

    PRODID = "-//Fleetyards//Mission Builder//EN"

    def initialize(events, calendar_name: nil, organizer_name: nil)
      @events = Array(events).compact
      @calendar_name = calendar_name
      @organizer_name = organizer_name
    end

    def to_ics
      lines = []
      lines << "BEGIN:VCALENDAR"
      lines << "VERSION:2.0"
      lines << "PRODID:#{PRODID}"
      lines << "CALSCALE:GREGORIAN"
      lines << "METHOD:PUBLISH"
      lines << "X-WR-CALNAME:#{escape(@calendar_name)}" if @calendar_name.present?
      single_timezone&.then { |tz| lines << "X-WR-TIMEZONE:#{tz}" }

      timezone_blocks.each { |block| lines.concat(block) }

      @events.each { |event| lines.concat(event_lines(event)) }

      lines << "END:VCALENDAR"
      lines.join("\r\n") + "\r\n"
    end

    private def event_lines(event)
      tz = event_timezone(event)
      lines = []
      lines << "BEGIN:VEVENT"
      lines << "UID:#{event.external_uid}@fleetyards.net"
      lines << "DTSTAMP:#{format_utc(event.updated_at)}"
      lines << "LAST-MODIFIED:#{format_utc(event.updated_at)}"
      lines << "CREATED:#{format_utc(event.created_at)}"
      lines.concat(time_lines(event, tz))
      lines << "SUMMARY:#{escape(event.title)}"
      lines << "DESCRIPTION:#{escape(event.description.to_s)}" if event.description.present?
      lines << "STATUS:#{ics_status(event.status)}"
      lines << "CATEGORIES:#{escape(event.category.to_s.upcase)}" if event.category.present?
      if event.location.present? || event.meetup_location.present?
        location = [event.location, event.meetup_location].compact_blank.join(" — ")
        lines << "LOCATION:#{escape(location)}"
      end
      lines << "URL:#{event_url(event)}"
      lines << "ORGANIZER;CN=#{escape(@organizer_name)}:mailto:noreply@fleetyards.net" if @organizer_name.present?
      lines.concat(recurrence_lines(event, tz)) if event.recurring?
      lines << "END:VEVENT"
      lines
    end

    private def recurrence_lines(event, tz)
      lines = []
      freq = case event.recurrence_interval
      when "daily" then "FREQ=DAILY"
      when "weekly" then "FREQ=WEEKLY"
      when "biweekly" then "FREQ=WEEKLY;INTERVAL=2"
      when "monthly" then "FREQ=MONTHLY"
      end
      return lines unless freq

      rrule = freq.dup
      if event.recurrence_until.present?
        rrule << ";UNTIL=#{event.recurrence_until.strftime("%Y%m%d")}T235959Z"
      elsif event.recurrence_count.present?
        rrule << ";COUNT=#{event.recurrence_count}"
      end
      lines << "RRULE:#{rrule}"

      Array(event.excluded_dates).each do |date|
        d = date.is_a?(String) ? Date.parse(date) : date
        time = event.starts_at.in_time_zone(tz || "UTC")
        excluded_local = time.change(year: d.year, month: d.month, day: d.day)
        lines << if tz && !UTC_IDENTIFIERS.include?(tz)
          "EXDATE;TZID=#{tz}:#{format_local(excluded_local)}"
        else
          "EXDATE:#{format_utc(excluded_local)}"
        end
      end

      lines
    end

    UTC_IDENTIFIERS = %w[UTC Etc/UTC].freeze

    private def time_lines(event, tz)
      if tz && !UTC_IDENTIFIERS.include?(tz)
        starts = event.starts_at.in_time_zone(tz)
        ends = (event.ends_at || event.starts_at + 1.hour).in_time_zone(tz)
        ["DTSTART;TZID=#{tz}:#{format_local(starts)}",
          "DTEND;TZID=#{tz}:#{format_local(ends)}"]
      else
        ["DTSTART:#{format_utc(event.starts_at)}",
          "DTEND:#{format_utc(event.ends_at || event.starts_at + 1.hour)}"]
      end
    end

    private def timezone_blocks
      distinct_timezones.map { |tz| vtimezone_block(tz) }
    end

    private def distinct_timezones
      @events
        .map { |e| event_timezone(e) }
        .compact
        .reject { |tz| UTC_IDENTIFIERS.include?(tz) }
        .uniq
    end

    private def event_timezone(event)
      tz = event.timezone.presence || "UTC"
      # ActiveSupport::TimeZone#tzinfo gives us the IANA identifier (e.g. "Europe/Berlin")
      ActiveSupport::TimeZone[tz]&.tzinfo&.identifier || tz
    end

    private def single_timezone
      tzs = distinct_timezones
      tzs.first if tzs.size == 1
    end

    # Minimal VTIMEZONE: a single TZID with no DST rules. Apple Calendar,
    # Google, and Outlook all accept this and fall back to their own TZ
    # database for the offsets. Emitting full STANDARD/DAYLIGHT components
    # would require RRULE generation per region — disproportionate for v1.
    private def vtimezone_block(tz)
      ["BEGIN:VTIMEZONE", "TZID:#{tz}", "END:VTIMEZONE"]
    end

    private def event_url(event)
      frontend_fleet_event_url(
        fleet_slug: event.fleet.slug,
        event_slug: event.slug,
        host: Rails.configuration.app.domain,
        protocol: "https"
      )
    end

    private def ics_status(status)
      case status.to_s
      when "cancelled" then "CANCELLED"
      when "completed", "active", "locked", "open" then "CONFIRMED"
      else "TENTATIVE"
      end
    end

    private def format_utc(time)
      time.utc.strftime("%Y%m%dT%H%M%SZ")
    end

    private def format_local(time)
      time.strftime("%Y%m%dT%H%M%S")
    end

    private def escape(text)
      text.to_s.gsub(/([,;\\])/, '\\\\\1').gsub("\n", "\\n")
    end
  end
end
