# frozen_string_literal: true

module FleetEvents
  # Splits a recurring event at one of its occurrences: the series ends the day
  # before, and a copy of it starts on that occurrence and runs to where the
  # original would have ended. Everything already attached to the later
  # occurrences -- signups, per-occurrence overrides, their Discord events,
  # skipped dates -- moves to the copy, so editing the copy is an edit of "this
  # and following" that nobody has to re-sign up for.
  class SeriesSplit
    class Error < StandardError; end

    class NotRecurring < Error; end

    class NotAnOccurrence < Error; end

    class AtSeriesStart < Error; end

    RESET_ATTRIBUTES = %w[
      id slug external_uid created_at updated_at
      discord_event_id discord_message_id discord_synced_at
      starting_soon_notified_at
    ].freeze

    attr_reader :event, :date

    def initialize(event, date)
      @event = event
      @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    end

    def call
      raise NotRecurring unless event.recurring?

      occurrence = find_occurrence
      raise NotAnOccurrence if occurrence.nil?
      raise AtSeriesStart if occurrence.to_date == event.starts_at.to_date

      FleetEvent.transaction do
        successor = build_successor(occurrence)
        successor.save!
        copy_cover_image(successor)
        copy_admins(successor)
        slot_map = copy_tree(successor)
        move_signups(successor, slot_map)
        move_occurrence_states(successor)

        event.update!(
          recurrence_until: date - 1.day,
          recurrence_count: nil,
          excluded_dates: event.excluded_dates.select { |d| d < date }
        )

        successor
      end
    end

    private def find_occurrence
      day = date.in_time_zone(Time.zone)
      event.occurrences(from: day.beginning_of_day, to: day.end_of_day, include_excluded: true).first
    end

    private def build_successor(occurrence)
      duration = event.ends_at && (event.ends_at - event.starts_at)

      successor = event.fleet.fleet_events.new(event.attributes.except(*RESET_ATTRIBUTES))
      successor.assign_attributes(
        starts_at: occurrence,
        ends_at: duration && occurrence + duration,
        recurrence_count: remaining_count,
        excluded_dates: event.excluded_dates.select { |d| d >= date },
        fleet_squadron_ids: event.fleet_squadron_ids
      )
      successor
    end

    # A count-bounded series keeps the total it promised: whatever the
    # original had not yet used up before the split carries over.
    private def remaining_count
      return nil if event.recurrence_count.blank?

      used = event.occurrences(from: event.starts_at, to: date.in_time_zone(Time.zone).beginning_of_day, include_excluded: true).size
      [event.recurrence_count - used, 1].max
    end

    private def copy_cover_image(successor)
      return unless event.cover_image.attached?

      successor.cover_image.attach(event.cover_image.blob)
    end

    private def copy_admins(successor)
      event.fleet_event_admins.each do |admin|
        successor.fleet_event_admins.create!(
          user_id: admin.user_id, role: admin.role, granted_by_id: admin.granted_by_id
        )
      end
    end

    # The copies skip validation on purpose: they mirror rows that were valid
    # when they were written, and a ship whose model has since been pulled from
    # the game must not stop the organiser from splitting the series.
    private def copy_tree(successor)
      slot_map = {}

      event.fleet_event_teams.includes(:fleet_event_slots, fleet_event_ships: [:fleet_event_slots, :fleet_event_ship_models]).find_each do |team|
        new_team = duplicate(team, fleet_event_id: successor.id)
        copy_slots(team, new_team, slot_map)

        team.fleet_event_ships.each do |ship|
          new_ship = duplicate(ship, fleet_event_team_id: new_team.id)
          ship.fleet_event_ship_models.each do |allowed|
            duplicate(allowed, fleet_event_ship_id: new_ship.id)
          end
          copy_slots(ship, new_ship, slot_map)
        end
      end

      slot_map
    end

    private def copy_slots(owner, new_owner, slot_map)
      owner.fleet_event_slots.each do |slot|
        slot_map[slot.id] = duplicate(slot, slottable: new_owner).id
      end
    end

    private def duplicate(record, **overrides)
      copy = record.dup
      copy.assign_attributes(created_at: nil, updated_at: nil, **overrides)
      copy.save!(validate: false)
      copy
    end

    private def move_signups(successor, slot_map)
      later = FleetEventSignup.where(fleet_event_id: event.id).where(occurrence_date: date..)

      later.where(fleet_event_slot_id: nil).update_all(fleet_event_id: successor.id)
      slot_map.each do |old_slot_id, new_slot_id|
        later.where(fleet_event_slot_id: old_slot_id)
          .update_all(fleet_event_id: successor.id, fleet_event_slot_id: new_slot_id)
      end
    end

    private def move_occurrence_states(successor)
      event.fleet_event_occurrence_states.where(occurrence_date: date..)
        .update_all(fleet_event_id: successor.id)
    end
  end
end
