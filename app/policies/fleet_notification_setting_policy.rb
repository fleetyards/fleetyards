# frozen_string_literal: true

class FleetNotificationSettingPolicy < FleetBasePolicy
  def show?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:notifications:manage"])
  end

  alias_rule :update?, to: :show?

  # Whoever holds the join role becomes a member without anyone answering a
  # request, so picking it is the same decision as handing out an invite link.
  def update_join_role?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:invites:manage", "fleet:invites:create"]) || false
  end
end
