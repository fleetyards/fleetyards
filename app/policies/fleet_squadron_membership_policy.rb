# frozen_string_literal: true

# Who may see and change who is in a squadron.
#
# Separate from `FleetSquadronPolicy` because the two answer different
# questions: deciding which squadrons exist is an admin's, posting people to
# them is an officer's. A role carrying `fleet:squadrons:members:manage` alone
# can fill a squadron it cannot rename.
#
# A squadron's own ranks reach the same rules from below. A Leader, Co-Leader
# or Officer manages the roster of their own squadron without any fleet
# privilege, but only for the people ranked under them: an Officer cannot
# remove the Leader who posted them. Appointing a Leader stays with the fleet.
class FleetSquadronMembershipPolicy < FleetBasePolicy
  authorize :fleet_squadron, optional: true

  # A squadron's roster is the fleet's roster narrowed, so it asks for both
  # reads: seeing that a squadron exists is not seeing who is in it.
  def index?
    return false unless accepted_fleet_membership&.has_access?(FleetSquadron::READ_PRIVILEGES)

    accepted_fleet_membership.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:read"])
  end

  # Whether the caller manages this roster at all. The row rules below narrow
  # it to the people the caller outranks.
  def create?
    fleet_wide? || actor_rank&.manages_members? || false
  end

  def manage_ranks?
    fleet_wide? || actor_rank&.manages_ranks? || false
  end

  def destroy?
    return true if fleet_wide?
    return false unless actor_rank&.manages_members?

    outranks?(record.fleet_squadron_role)
  end

  # Reads the pending change off the row, so the controller assigns the
  # attributes before it asks.
  def update?
    return true if fleet_wide?
    return false if record.fleet_squadron_role_id_changed? && !rank_change_allowed?
    return true if (record.changed - ["fleet_squadron_role_id"]).empty?

    destroy?
  end

  private def rank_change_allowed?
    old_rank = FleetSquadronRole.find_by(id: record.fleet_squadron_role_id_was)
    new_rank = record.fleet_squadron_role
    return false if old_rank.blank? || new_rank.blank?

    # Stepping down is always one's own to do.
    return new_rank.position > old_rank.position if record.id == actor_row&.id

    return false unless actor_rank&.manages_ranks?

    outranks?(old_rank) && outranks?(new_rank)
  end

  private def outranks?(rank)
    actor_rank.present? && rank.present? && rank.position > actor_rank.position
  end

  private def fleet_wide?
    accepted_fleet_membership&.has_access?(FleetSquadron::MEMBERS_MANAGE_PRIVILEGES) || false
  end

  private def actor_rank
    actor_row&.fleet_squadron_role
  end

  private def actor_row
    return @actor_row if defined?(@actor_row)

    squadron_id = record.try(:fleet_squadron_id) || fleet_squadron&.id

    @actor_row = if squadron_id.present? && accepted_fleet_membership.present?
      FleetSquadronMembership
        .includes(:fleet_squadron_role)
        .find_by(fleet_squadron_id: squadron_id, fleet_membership_id: accepted_fleet_membership.id)
    end
  end
end
