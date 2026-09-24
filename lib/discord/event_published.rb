# frozen_string_literal: true

require "discord/event_message"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # Posted once when an event is published. A recurring series is announced
  # once, from its first occurrence, rather than once per week.
  class EventPublished < EventMessage
    private def get_title
      I18n.t("discord.event_published.title", title: event_title)
    end

    private def get_message
      [starts, recurrence, availability].compact.join(" · ")
    end

    # Discord renders a timestamp tag in each reader's own timezone, which a
    # fleet spread across continents needs more than any fixed zone.
    private def starts
      "<t:#{starts_at.to_i}:F>"
    end

    private def recurrence
      return nil unless event.recurring? && event.recurrence_interval.present?

      I18n.t("discord.event_published.recurrence.#{event.recurrence_interval}")
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
