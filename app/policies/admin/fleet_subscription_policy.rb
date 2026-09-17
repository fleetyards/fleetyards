# frozen_string_literal: true

module Admin
  # Same access as supporter contributions, deliberately. A subscription is the
  # entitlement half of the same story -- the person who administers what was
  # paid is the one who comps a partner org or answers a support ticket -- and a
  # separate privilege would only ever be granted alongside that one.
  class FleetSubscriptionPolicy < BasePolicy
    private def resource_access
      [:supporters]
    end
  end
end
