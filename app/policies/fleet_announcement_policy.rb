# frozen_string_literal: true

class FleetAnnouncementPolicy < FleetBasePolicy
  # Everyone in the fleet reads what its officers post; that is the point.
  def index?
    accepted_fleet_membership.present?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  def manage?
    accepted_fleet_membership&.has_access?(FleetAnnouncement::MANAGE_PRIVILEGES) || false
  end

  params_filter do |params|
    params.permit(:body, :expires_at)
  end
end
