# frozen_string_literal: true

# A member listed for a slot, by their squadron row: leaving the squadron
# deletes the row and takes them off every list with it. The ship, when one is
# named, has to be the member's own.
module SlotCandidate
  extend ActiveSupport::Concern

  # What a rendered candidate reads: the member's name and the ship's model.
  RENDER_PRELOADS = [{fleet_squadron_membership: {fleet_membership: :user}}, {vehicle: :model}].freeze

  included do
    belongs_to :fleet_squadron_membership
    belongs_to :vehicle, optional: true

    default_scope -> { order(position: :asc) }

    validate :membership_belongs_to_the_fleet
    validate :vehicle_belongs_to_the_member
  end

  private def membership_belongs_to_the_fleet
    return if fleet_squadron_membership.blank?

    squadron = fleet_squadron_membership.fleet_squadron
    squadron_id = slot_squadron_id
    return errors.add(:fleet_squadron_membership, :not_in_squadron) if squadron_id.present? && squadron.id != squadron_id

    fleet_id = slot_fleet_id
    return if fleet_id.blank? || squadron.fleet_id == fleet_id

    errors.add(:fleet_squadron_membership, :not_in_fleet)
  end

  private def vehicle_belongs_to_the_member
    return if vehicle.blank? || fleet_squadron_membership.blank?
    return if vehicle.user_id == fleet_squadron_membership.fleet_membership&.user_id

    errors.add(:vehicle, :not_owned)
  end
end
