# frozen_string_literal: true

require "discord/webhook"
require "discord/event_availability"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # The reminder Discord cannot write itself.
  #
  # Discord's own scheduled-event reminder knows the time and nothing else.
  # Fleetyards knows the slots, so "starts in 25 minutes · 6 of 14 slots open"
  # carries information the platform has no access to.
  #
  # Posts through the fleet's own `discord_webhook_url` rather than the bot, so
  # this works in servers that never installed the bot and needs no permission
  # at all. That column has been writable since the Discord settings shipped and
  # nothing has ever posted to it.
  class EventReminder < ::Discord::Webhook
    private def event
      options[:event]
    end

    private def occurrence_date
      options[:occurrence_date]
    end

    private def setting
      event&.fleet&.fleet_notification_setting
    end

    # Overrides the global announcements endpoint from the base class: this
    # message belongs to one fleet, not to the Fleetyards feed.
    private def get_webhook_endpoint
      setting&.discord_webhook_url.presence
    end

    private def get_title
      I18n.t("discord.event_reminder.title", title: event_title)
    end

    private def get_message
      [starts_in, availability].compact.join(" · ")
    end

    private def get_url
      frontend_fleet_event_url(fleet_slug: event.fleet.slug, event_slug: event.slug)
    end

    # Title, start time and availability are all per-occurrence, and the event
    # list needs exactly the same three. Sharing them is what keeps the reminder
    # and the list from disagreeing about how many slots are open.
    private def availability_for_occurrence
      @availability_for_occurrence ||= ::Discord::EventAvailability.new(event, occurrence_date: occurrence_date)
    end

    private def event_title
      availability_for_occurrence.title
    end

    private def starts_at
      availability_for_occurrence.starts_at
    end

    private def starts_in
      minutes = ((starts_at - Time.current) / 60).round
      return I18n.t("discord.event_reminder.starting_now") if minutes <= 0

      I18n.t("discord.event_reminder.starts_in", count: minutes)
    end

    private def availability
      availability_for_occurrence.label
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
