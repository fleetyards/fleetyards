# frozen_string_literal: true

# The feed itself is for anybody in the fleet. What it carries is narrowed per
# source by that source's own policy, so a member who may read nothing but
# events still gets a feed, of events.
class FleetActivityPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership.present?
  end
end
