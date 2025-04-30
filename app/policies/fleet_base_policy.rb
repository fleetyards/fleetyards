class FleetBasePolicy < ApplicationPolicy
  authorize :fleet, optional: true

  private def fleet_membership
    if record.try(:fleet_id)
      user&.fleet_memberships&.find_by(fleet_id: record.fleet_id)
    elsif fleet.present?
      user&.fleet_memberships&.find_by(fleet_id: fleet.id)
    elsif record.try(:id)
      user&.fleet_memberships&.find_by(fleet_id: record&.id)
    end
  end

  private def accepted_fleet_membership
    if fleet_membership&.accepted?
      fleet_membership
    end
  end

  private def invited_fleet_membership
    if fleet_membership&.invited?
      fleet_membership
    end
  end
end
