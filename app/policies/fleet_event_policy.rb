# frozen_string_literal: true

class FleetEventPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:read"])
  end

  alias_rule :show?, to: :index?

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:create"])
  end

  def update?
    return true if creator?
    return true if event_admin?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:update"])
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:delete"])
  end

  # Granting/revoking per-event admin roles is restricted to the original
  # event creator and fleet-level managers.
  def manage_admins?
    return true if creator?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage"])
  end

  alias_rule :publish?, :lock_signups?, :unlock_signups?, :start?, :complete?, :cancel?, to: :update?

  params_filter do |params|
    params.permit(
      :title, :description, :briefing,
      :starts_at, :ends_at, :timezone,
      :location, :meetup_location,
      :visibility, :category, :scenario,
      :max_attendees, :auto_lock_enabled, :auto_lock_minutes_before,
      :cover_image, :cover_image_preset, :signup_approval
    )
  end

  private def creator?
    record.respond_to?(:created_by_id) && user && record.created_by_id == user.id
  end

  private def event_admin?
    record.respond_to?(:event_admin?) && record.event_admin?(user)
  end

  private def draft?
    record.respond_to?(:status) && record.status == "draft"
  end
end
