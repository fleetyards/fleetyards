# frozen_string_literal: true

module FleetEvents
  # Hands a slot to the members listed for it, one at a time. The first who
  # can take it gets an invited signup and is asked to confirm; whoever
  # declines, withdraws or leaves is marked as passed, and the next one is
  # asked.
  #
  # Only an event that is open for signups and still ahead invites anybody: a
  # draft would announce itself through the invitation, and a recurring event
  # is signed up for one occurrence at a time, which a single list of
  # candidates cannot follow -- there the list stays for whoever runs it.
  class SlotInvites
    INVITING_STATUSES = %w[open locked].freeze

    COMMITTED_STATUSES = %w[confirmed pending].freeze

    def self.offer_all!(event)
      return unless inviting?(event)

      teams = event.fleet_event_teams.select(:id)
      ships = FleetEventShip.where(fleet_event_team_id: teams).select(:id)

      FleetEventSlot
        .where(slottable_type: "FleetEventTeam", slottable_id: teams)
        .or(FleetEventSlot.where(slottable_type: "FleetEventShip", slottable_id: ships))
        .where(id: FleetEventSlotCandidate.waiting.select(:fleet_event_slot_id))
        .each { |slot| new(slot).offer! }
    end

    def self.pass_on!(slot_id, fleet_membership_id)
      slot = FleetEventSlot.find_by(id: slot_id)
      return if slot.blank?

      slot.fleet_event_slot_candidates
        .waiting
        .where(fleet_squadron_membership_id: FleetSquadronMembership.where(fleet_membership_id:).select(:id))
        .update_all(passed_at: Time.current, updated_at: Time.current)

      new(slot).offer!
    end

    def self.inviting?(event)
      event.present? &&
        !event.recurring? &&
        INVITING_STATUSES.include?(event.status) &&
        event.starts_at.present? && event.starts_at > Time.current
    end

    attr_reader :slot

    def initialize(slot)
      @slot = slot
    end

    def offer!
      event = slot.fleet_event
      return unless self.class.inviting?(event)
      return if taken?

      slot.fleet_event_slot_candidates.waiting
        .includes(:vehicle, fleet_squadron_membership: %i[fleet_membership fleet_squadron])
        .each do |candidate|
          # A squadron that switched its flights off sends no invitations; its
          # members stay listed for when it switches them back on.
          next unless candidate.fleet_squadron_membership&.fleet_squadron&.flights_enabled?

          signup = invite(event, candidate)
          return signup if signup

          candidate.update_columns(passed_at: Time.current, updated_at: Time.current)
        end

      nil
    end

    private def taken?
      slot.fleet_event_signups.where(occurrence_date: nil).where.not(status: "withdrawn").exists?
    end

    # A member already waiting in the event's pool is moved into the slot
    # rather than signed up twice; one already in another slot has a seat.
    # Somebody who already committed to the event keeps that commitment in the
    # slot: turning it into an invitation would let a decline drop them from
    # the event they said yes to.
    private def invite(event, candidate)
      membership = candidate.fleet_membership
      return unless membership&.kept? && membership.accepted?

      existing = event.fleet_event_signups
        .where(fleet_membership: membership, occurrence_date: nil)
        .where.not(status: "withdrawn")
        .first
      return if existing&.fleet_event_slot_id.present?

      signup = existing || event.fleet_event_signups.new(fleet_membership: membership)
      committed = existing.present? && COMMITTED_STATUSES.include?(existing.status)
      signup.assign_attributes(fleet_event_slot: slot, status: committed ? existing.status : "invited")
      signup.vehicle = candidate.vehicle if candidate.vehicle&.user_id == membership.user_id

      return unless signup.save_without_conflict

      ActiveRecord.after_all_transactions_commit do
        if committed
          ActiveSupport::Notifications.instrument("fleet_event_signup.assigned", signup:, previous_slot_id: nil)
        else
          ActiveSupport::Notifications.instrument("fleet_event_signup.invited", signup:)
        end
      end

      signup
    end
  end
end
