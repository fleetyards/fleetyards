# frozen_string_literal: true

class MissionPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:read"])
  end

  alias_rule :show?, to: :index?

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:create"])
  end

  def update?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:update"])
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:missions:manage", "fleet:missions:delete"])
  end

  params_filter do |params|
    params.permit(:title, :description, :archived_at, :category, :scenario, :cover_image, :cover_image_preset)
  end
end
