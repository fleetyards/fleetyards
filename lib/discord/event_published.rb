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

    # A series that has run out, or a one-off published after it happened, has
    # nothing ahead of it to announce.
    def upcoming?
      starts_at > Time.current && (!event.recurring? || occurrence_date.present?)
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
      frequency = event.recurrence_frequency
      return nil unless event.recurring? && frequency.present?

      interval = if event.recurrence_step > 1
        I18n.t("discord.event_published.recurrence.every_n.#{frequency}", count: event.recurrence_step)
      else
        I18n.t("discord.event_published.recurrence.#{frequency}")
      end

      days = event.recurrence_days
      return interval if days.empty?

      names = I18n.t("date.abbr_day_names")
      I18n.t("discord.event_published.recurrence.on_days",
        interval: interval,
        days: days.sort_by { |wday| (wday - 1) % 7 }.map { |wday| names[wday] }.to_sentence)
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
