# frozen_string_literal: true

require "discord/event_message"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # The reminder Discord cannot write itself.
  #
  # Discord's own scheduled-event reminder knows the time and nothing else.
  # Fleetyards knows the slots, so "starts in 25 minutes · 6 of 14 slots open"
  # carries information the platform has no access to.
  class EventReminder < EventMessage
    private def get_title
      I18n.t("discord.event_reminder.title", title: event_title)
    end

    private def get_message
      [starts_in, availability].compact.join(" · ")
    end

    private def starts_in
      minutes = ((starts_at - Time.current) / 60).round
      return I18n.t("discord.event_reminder.starting_now") if minutes <= 0

      I18n.t("discord.event_reminder.starts_in", count: minutes)
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
