# frozen_string_literal: true

require "discord/event_announcement"
require "discord/event_availability"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # A message about one event, or one occurrence of a recurring one, posted
  # wherever Discord::EventAnnouncement says that event may be announced.
  class EventMessage
    include RoutingConcern

    attr_reader :event, :occurrence_date

    def initialize(event:, occurrence_date: nil)
      @event = event
      @occurrence_date = occurrence_date
    end

    def run
      EventAnnouncement.new(event).deliver(content)
    end

    def content
      ["**#{get_title}**", get_message.presence, get_url].compact.join("\n")
    end

    private def get_title
      raise NotImplementedError
    end

    private def get_message
    end

    private def get_url
      frontend_fleet_event_url(fleet_slug: event.fleet.slug, event_slug: event.slug)
    end

    # Title, start time and availability are all per-occurrence, and the event
    # list needs exactly the same three. Sharing them is what keeps a message
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

    private def availability
      availability_for_occurrence.label
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
