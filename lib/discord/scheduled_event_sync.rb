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

    attr_reader :event, :setting

    def initialize(event)
      @event = event
      @setting = event.fleet&.fleet_notification_setting
    end

    def runnable?
      ApiClient.configured? && setting&.discord_guild_id.present?
    end

    def upsert!
      return unless runnable?

      payload = build_payload
      response =
        if event.discord_event_id.present?
          api.update_guild_scheduled_event(setting.discord_guild_id, event.discord_event_id, payload)
        else
          api.create_guild_scheduled_event(setting.discord_guild_id, payload)
        end

      if response && response["id"].present?
        event.update_columns(
          discord_event_id: response["id"],
          discord_synced_at: Time.current
        )
      end

      response
    rescue ApiClient::Error => e
      # If Discord 404s the event id (was deleted there), reset and try once
      # more so we recover from out-of-band deletion.
      if e.status == 404 && event.discord_event_id.present?
        event.update_columns(discord_event_id: nil, discord_synced_at: nil)
        retry
      end
      raise
    end

    def delete!
      return unless runnable?
      return if event.discord_event_id.blank?

      api.delete_guild_scheduled_event(setting.discord_guild_id, event.discord_event_id)
      event.update_columns(discord_event_id: nil, discord_synced_at: Time.current)
    rescue ApiClient::Error => e
      # If it's already gone, just clear our reference.
      raise unless e.status == 404
      event.update_columns(discord_event_id: nil, discord_synced_at: Time.current)
    end

    private def build_payload
      payload = {
        name: event.title.to_s.first(100),
        description: description_for(event),
        scheduled_start_time: event.starts_at&.iso8601,
        scheduled_end_time: (event.ends_at || event.starts_at + DEFAULT_DURATION)&.iso8601,
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
          location: event.meetup_location.presence ||
            event.location.presence ||
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

      preset = event.cover_image_preset.presence
      return nil if preset.blank?

      # Discord's image upload doesn't accept webp, so prefer jpg.
      preset_root = Rails.root.join("app/frontend/images/missions")
      candidate = %w[jpg jpeg png].lazy
        .map { |ext| preset_root.join("#{preset}.#{ext}") }
        .find { |path| File.exist?(path) }

      return nil unless candidate

      mime = case candidate.extname
      when ".png" then "image/png"
      else "image/jpeg"
      end
      [File.binread(candidate), mime]
    end

    private def cancelled?
      event.status == "cancelled"
    end

    private def description_for(event)
      base = event.description.presence || event.briefing.presence || ""
      [
        base,
        event.fleet ? "\n\nView on Fleetyards: https://fleetyards.net/fleets/#{event.fleet.slug}/events/#{event.slug}" : nil
      ].compact.join.first(1000)
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
