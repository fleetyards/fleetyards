# frozen_string_literal: true

# One member a template or flight slot is meant for, in order: the first is
# who the slot goes to, the rest step in when somebody before them cannot.
class MissionSlotCandidate < ApplicationRecord
  include SlotCandidate

  belongs_to :mission_slot, touch: true

  private def slot_fleet_id
    mission_slot&.fleet_id
  end

  private def slot_squadron_id
    mission_slot&.flight&.fleet_squadron_id
  end
end
