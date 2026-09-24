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

  def update?
    accepted_fleet_membership&.has_access?([*FleetSquadron::MANAGE_PRIVILEGES, "fleet:squadrons:update"]) || false
  end

  # Arranging the list is the same authority as editing what is in it: whoever
  # may rename a squadron may say where it sits.
  def move?
    update?
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
    params.permit(:name, :short_description, :description, :color, :team, :icon)
  end
end
