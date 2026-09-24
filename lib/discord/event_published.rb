# frozen_string_literal: true

require "discord/event_message"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # Posted once when an event is published. A recurring series is announced
  # once, rather than once per week, from its next occurrence: a series can
  # be published well after the date it was first set to start.
  class EventPublished < EventMessage
    UPCOMING_LOOKAHEAD = 1.year

    def initialize(event:, occurrence_date: nil)
      super(event: event, occurrence_date: occurrence_date || next_occurrence_date(event))
    end

    private def next_occurrence_date(event)
      return nil unless event.recurring?

      now = Time.current
      event.occurrences(from: now, to: now + UPCOMING_LOOKAHEAD).first&.to_date
    end

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
