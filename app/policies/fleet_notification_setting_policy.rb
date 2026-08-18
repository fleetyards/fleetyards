# frozen_string_literal: true

class FleetNotificationSettingPolicy < FleetBasePolicy
  def show?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:notifications:manage"])
  end

  alias_rule :update?, to: :show?
end
