# frozen_string_literal: true

class FleetSquadronPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(FleetSquadron::READ_PRIVILEGES) || false
  end

  def show?
    index?
  end

  def create?
    accepted_fleet_membership&.has_access?([*FleetSquadron::MANAGE_PRIVILEGES, "fleet:squadrons:create"]) || false
  end

  # Reads the pending change off the record, so the controller assigns the
  # attributes before it asks: the squadron's Leader may change all of it, its
  # Co-Leader the role filter and nothing else.
  def update?
    return true if edit?
    return false unless role_filter_only_change?

    update_role_filter?
  end

  # Everything about the squadron: the fleet's squadron editors, and whoever
  # the squadron itself puts in charge, whatever their fleet role.
  def edit?
    edit_squadrons? || squadron_rank&.edits_squadron? || false
  end

  def update_role_filter?
    edit? || squadron_rank&.manages_ranks? || false
  end

  # The order is the fleet's list, not part of any one squadron, so a rank
  # inside a squadron does not reach it.
  def move?
    edit_squadrons?
  end

  def destroy?
    accepted_fleet_membership&.has_access?([*FleetSquadron::MANAGE_PRIVILEGES, "fleet:squadrons:delete"]) || false
  end

  # A squadron has no visibility of its own -- it is the roster grouped, and the
  # roster is one thing or nothing. So the scope carries only the read gate, and
  # it is the same question `show?` asks; FleetSquadronPolicyTest holds the two
  # together.
  #
  # Needs the fleet context. Every caller is scoped to one fleet already, and
  # reading the fleet off the relation instead would quietly answer `none` for a
  # caller that forgot to pass it rather than saying so.
  relation_scope do |relation|
    raise ArgumentError, "FleetSquadronPolicy's relation scope needs a fleet context" if fleet.blank?

    next relation.none unless index?

    relation
  end


  params_filter do |params|
    params.permit(:name, :short_description, :description, :color, :team, :flights_enabled, :icon, :discord_channel_id,
      classifications: [], foci: [])
  end

  ROLE_FILTER_ATTRIBUTES = %w[classifications foci].freeze

  private def edit_squadrons?
    accepted_fleet_membership&.has_access?([*FleetSquadron::MANAGE_PRIVILEGES, "fleet:squadrons:update"]) || false
  end

  private def role_filter_only_change?
    (record.changed - ROLE_FILTER_ATTRIBUTES).empty? && record.attachment_changes.empty?
  end

  # Only for somebody who can read the squadron at all, the way the roster
  # rules count a rank.
  private def squadron_rank
    return @squadron_rank if defined?(@squadron_rank)

    @squadron_rank = if index? && record.is_a?(FleetSquadron) && record.persisted?
      FleetSquadronMembership
        .includes(:fleet_squadron_role)
        .find_by(fleet_squadron_id: record.id, fleet_membership_id: accepted_fleet_membership.id)
        &.fleet_squadron_role
    end
  end
end
