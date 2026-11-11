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

    def self.offer_all!(event)
      return unless inviting?(event)

      FleetEventSlot
        .where(id: FleetEventSlotCandidate.waiting.select(:fleet_event_slot_id))
        .includes(:slottable)
        .select { |slot| slot.fleet_event&.id == event.id }
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
        .includes(:vehicle, fleet_squadron_membership: :fleet_membership)
        .each do |candidate|
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
    private def invite(event, candidate)
      membership = candidate.fleet_membership
      return unless membership&.kept? && membership.accepted?

      existing = event.fleet_event_signups
        .where(fleet_membership: membership, occurrence_date: nil)
        .where.not(status: "withdrawn")
        .first
      return if existing&.fleet_event_slot_id.present?

      signup = existing || event.fleet_event_signups.new(fleet_membership: membership)
      signup.assign_attributes(fleet_event_slot: slot, status: "invited")
      signup.vehicle = candidate.vehicle if candidate.vehicle&.user_id == membership.user_id

      return unless signup.save_without_conflict

      ActiveRecord.after_all_transactions_commit do
        ActiveSupport::Notifications.instrument("fleet_event_signup.invited", signup:)
      end

      signup
    end
  end
end
