# frozen_string_literal: true

# One member an event slot is offered to, in order. Whoever is offered the
# slot gets an invited signup; somebody who declines, withdraws or leaves is
# marked as passed, and the slot goes to the next one still able to take it.
class FleetEventSlotCandidate < ApplicationRecord
  include SlotCandidate

  belongs_to :fleet_event_slot, touch: true

  scope :waiting, -> { where(passed_at: nil) }

  def fleet_membership
    fleet_squadron_membership&.fleet_membership
  end

  private def slot_fleet_id
    fleet_event_slot&.fleet_event&.fleet_id
  end

  private def slot_squadron_id
    nil
  end
end
