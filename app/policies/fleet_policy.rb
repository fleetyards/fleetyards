class FleetPolicy < FleetBasePolicy
  default_rule :manage?

  def create?
    true
  end

  def invites?
    true
  end

  def my?
    true
  end

  def show?
    accepted_fleet_membership.present?
  end

  def show_for_membership?
    fleet_membership.present?
  end

  def manage?
    accepted_fleet_membership&.has_access?(["fleet:manage"])
  end

  def update?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:update", "fleet:update:description", "fleet:update:images"])
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:delete"])
  end

  relation_scope do |relation|
    relation.where(id: user.fleet_ids)
  end

  params_filter(:create) do |params|
    params.permit(%i[fid name])
  end

  params_filter do |params|
    allowed_params = []

    if accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:update"])
      allowed_params << [
        :fid, :name, :description, :logo, :background_image, :public_fleet, :public_fleet_stats,
        :remove_logo, :remove_background, :homepage, :rsi_sid, :discord, :ts, :youtube,
        :twitch, :guilded
      ]
    end

    if accepted_fleet_membership&.has_access?(["fleet:update:description"])
      allowed_params << [:description]
    end

    if accepted_fleet_membership&.has_access?(["fleet:update:images"])
      allowed_params << [:logo, :background_image, :remove_logo, :remove_background]
    end

    params.permit(*allowed_params.flatten)
  end
end
