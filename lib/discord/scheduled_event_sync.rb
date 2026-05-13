# frozen_string_literal: true

require "discord/api_client"

module Discord
  # Maps a FleetEvent to a Discord guild scheduled event. Idempotent: creates
  # if no discord_event_id yet, patches if there is one, deletes on cancel /
  # destroy. Skips silently when the fleet hasn't connected Discord or the
  # bot token isn't configured.
  class ScheduledEventSync
    PRIVACY_LEVEL_GUILD_ONLY = 2
    ENTITY_TYPE_VOICE = 2
    ENTITY_TYPE_EXTERNAL = 3

    # Discord requires every scheduled event to have an end time; default to
    # +2h when the fleet event doesn't carry one.
    DEFAULT_DURATION = 2.hours

    attr_reader :event, :setting, :occurrence_date, :state

    def initialize(event, occurrence_date: nil)
      @event = event
      @setting = event.fleet&.fleet_notification_setting
      @occurrence_date = occurrence_date
      @state = event.occurrence_state_for(occurrence_date, build: true) if occurrence_date
    end

    def runnable?
      ApiClient.configured? && setting&.discord_guild_id.present?
    end

    def upsert!
      return unless runnable?

      payload = build_payload
      response =
        if existing_discord_event_id.present?
          api.update_guild_scheduled_event(setting.discord_guild_id, existing_discord_event_id, payload)
        else
          api.create_guild_scheduled_event(setting.discord_guild_id, payload)
        end

      if response && response["id"].present?
        persist_discord_event_id!(response["id"])
      end

      response
    rescue ApiClient::Error => e
      # If Discord 404s the event id (was deleted there), reset and try once
      # more so we recover from out-of-band deletion.
      if e.status == 404 && existing_discord_event_id.present?
        clear_discord_event_id!
        retry
      end
      raise
    end

    def delete!
      return unless runnable?
      return if existing_discord_event_id.blank?

      api.delete_guild_scheduled_event(setting.discord_guild_id, existing_discord_event_id)
      clear_discord_event_id!
    rescue ApiClient::Error => e
      # If it's already gone, just clear our reference.
      raise unless e.status == 404
      clear_discord_event_id!
    end

    private def existing_discord_event_id
      state ? state.discord_event_id : event.discord_event_id
    end

    private def persist_discord_event_id!(id)
      if state
        state.update!(discord_event_id: id, discord_synced_at: Time.current)
      else
        event.update_columns(
          discord_event_id: id,
          discord_synced_at: Time.current
        )
      end
    end

    private def clear_discord_event_id!
      if state
        state.update!(discord_event_id: nil, discord_synced_at: Time.current)
      else
        event.update_columns(discord_event_id: nil, discord_synced_at: Time.current)
      end
    end

    private def build_payload
      payload = {
        name: effective_title.to_s.first(100),
        description: description_for(event),
        scheduled_start_time: effective_starts_at&.iso8601,
        scheduled_end_time: effective_ends_at&.iso8601,
        privacy_level: PRIVACY_LEVEL_GUILD_ONLY
      }

      if setting.discord_channel_id.present?
        payload[:entity_type] = ENTITY_TYPE_VOICE
        payload[:channel_id] = setting.discord_channel_id
        payload[:entity_metadata] = nil
      else
        payload[:entity_type] = ENTITY_TYPE_EXTERNAL
        payload[:channel_id] = nil
        payload[:entity_metadata] = {
          location: effective_meetup_location.presence ||
            effective_location.presence ||
            "Star Citizen"
        }
      end

      if (image = cover_image_data_uri)
        payload[:image] = image
      end

      if cancelled?
        payload[:status] = 4 # COMPLETED — closes the event without deletion
      end

      payload
    end

    private def effective_title = state&.title.presence || event.title
    private def effective_location = state&.location.presence || event.location
    private def effective_meetup_location = state&.meetup_location.presence || event.meetup_location

    private def effective_starts_at
      return event.starts_at unless occurrence_date

      tz = event.timezone.presence || "UTC"
      base = event.starts_at.in_time_zone(tz)
      base.change(
        year: occurrence_date.year,
        month: occurrence_date.month,
        day: occurrence_date.day
      )
    end

    private def effective_ends_at
      base = effective_starts_at
      return nil if base.nil?

      duration = event.ends_at ? (event.ends_at - event.starts_at) : DEFAULT_DURATION
      base + duration
    end

    # Discord accepts cover images as base64 data URIs in the payload.
    # We try the attached cover_image first, then fall back to the bundled
    # preset asset that matches event.cover_image_preset.
    private def cover_image_data_uri
      bytes, mime = cover_image_bytes
      return nil unless bytes

      "data:#{mime};base64,#{Base64.strict_encode64(bytes)}"
    rescue => e
      Rails.logger.warn("[discord-sync] failed to read cover image for event #{event.id}: #{e.class}: #{e.message}")
      nil
    end

    private def cover_image_bytes
      if event.cover_image.attached?
        return [event.cover_image.download, event.cover_image.content_type || "image/jpeg"]
      end

      # Mirror the frontend's useMissionCover fallback chain: explicit
      # preset → category default. So the Discord payload picks up the
      # same cover the user sees in the UI even when the column wasn't
      # explicitly set (e.g., events created without picking a preset).
      candidates = [event.cover_image_preset.presence, event.category.to_s.presence].compact
      return nil if candidates.empty?

      preset_root = Rails.root.join("app/frontend/images/missions")
      file = candidates.flat_map do |stem|
        %w[jpg jpeg png].map { |ext| preset_root.join("#{stem}.#{ext}") }
      end.find { |path| File.exist?(path) }

      return nil unless file

      mime = case file.extname
      when ".png" then "image/png"
      else "image/jpeg"
      end
      [File.binread(file), mime]
    end

    private def cancelled?
      return true if state&.cancelled?
      event.status == "cancelled"
    end

    private def description_for(event)
      base = event.description.presence || event.briefing.presence
      [
        # Sesh-style "chip" line built from emoji + mentions + Discord's
        # `<t:UNIX:R>` relative-time tag. Lives inside the description because
        # Discord's real chips (creator/attendees/time) reflect bot-side data
        # we can't override.
        chip_line,
        event_short_url ? "**Open in Fleetyards:** <#{event_short_url}>" : nil,
        base
      ].compact.join("\n\n").first(1000)
    end

    private def chip_line
      parts = ["🚩 #{host_chip}", "👥 #{confirmed_count} (+#{interested_count})"]
      starts = effective_starts_at
      parts << "⏳ <t:#{starts.to_i}:R>" if starts
      parts.join("  ·  ")
    end

    private def host_chip
      uid = event.created_by&.discord_uid
      return "<@#{uid}>" if uid.present?
      event.created_by&.username.presence || "Star Citizen"
    end

    private def confirmed_count
      event.fleet_event_signups.where(status: "confirmed").count
    end

    private def interested_count
      event.fleet_event_signups.where(status: "interested").count
    end

    # Public on the model so the frontend's "Sync to Discord" button can
    # render the same canonical short URL (and so we can verify the route
    # in tests without spinning up the request stack).
    private def event_short_url
      return nil if event.fleet&.fid.blank? || event.slug.blank?

      domain = Rails.application.config.app.short_domain.presence ||
        Rails.application.config.app.domain
      scheme = Rails.env.production? ? "https" : "http"
      "#{scheme}://#{domain}/fe/#{event.fleet.fid}/#{event.slug}"
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
