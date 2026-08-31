# frozen_string_literal: true

require "discord/webhook"

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

    private def event_title
      state&.title.presence || event.title
    end

    private def state
      return nil if occurrence_date.blank?

      event.occurrence_state_for(occurrence_date, build: false)
    end

    private def starts_at
      return event.starts_at if occurrence_date.blank?

      # A recurring occurrence keeps the parent's time of day on its own date.
      event.starts_at.change(
        year: occurrence_date.year,
        month: occurrence_date.month,
        day: occurrence_date.day
      )
    end

    private def starts_in
      minutes = ((starts_at - Time.current) / 60).round
      return I18n.t("discord.event_reminder.starting_now") if minutes <= 0

      I18n.t("discord.event_reminder.starts_in", count: minutes)
    end

    # Slots are the point of the message, but plenty of events have none --
    # those get the signup count instead of "0 of 0 slots open", which reads
    # like a full event.
    private def availability
      total = event.slots.count
      return signups if total.zero?

      I18n.t("discord.event_reminder.slots", open: total - taken_slots, total: total)
    end

    private def signups
      count = signups_scope.count
      return nil if count.zero?

      I18n.t("discord.event_reminder.signups", count: count)
    end

    private def taken_slots
      signups_scope.where.not(fleet_event_slot_id: nil).count
    end

    private def signups_scope
      scope = event.fleet_event_signups.where.not(status: "withdrawn")
      return scope if occurrence_date.blank?

      scope.where(occurrence_date: occurrence_date)
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
