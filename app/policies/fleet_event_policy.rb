# frozen_string_literal: true

class FleetEventPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage", "fleet:events:read"])
  end

  # Not an alias any more: a squadron event is on the board for the squadrons
  # it names, and reading the list is no longer the same question as reading
  # one of them.
  def show?
    return false unless index?

    record.blank? || manage? || record.visible_to_squadrons_of?(accepted_fleet_membership)
  end

  # Whoever may run the fleet's events reaches all of them, including the
  # squadron ones they are not in -- which they may well have created.
  def manage?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:events:manage"]) || false
  end

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
  alias_rule :unarchive?, to: :destroy?

  params_filter do |params|
    params.permit(
      :title, :description, :briefing,
      :starts_at, :ends_at, :timezone,
      :location, :meetup_location,
      :visibility, :category, :scenario,
      :max_attendees, :auto_lock_enabled, :auto_lock_minutes_before,
      :cover_image, :cover_image_preset, :signup_approval,
      :recurring, :recurrence_interval, :recurrence_until, :recurrence_count,
      :recurrence_every,
      excluded_dates: [], fleet_squadron_ids: [], recurrence_weekdays: []
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
