# frozen_string_literal: true

# Declare `before_action :check_friends_feature` (or the fleet one) after the
# doorkeeper callbacks, so an unauthenticated request still gets a 401 rather
# than a 403 that tells it what exists.
#
# Two flags rather than one. `FeatureSetting` carries `self_service_user` and
# `self_service_fleet` independently: a user switching friends on for
# themselves has nothing to do with a fleet's admins switching alliances on for
# the whole org, and the two roll out on their own schedules. The same split
# `hangar_inventories` and `fleet_logistics` already make.
module RelationshipsFeatureConcern
  extend ActiveSupport::Concern

  private def check_friends_feature
    return if feature_enabled?("friends")

    feature_unavailable
  end

  private def check_fleet_allies_feature(fleet)
    return if feature_enabled?("fleet_allies", fleet)

    feature_unavailable
  end

  private def feature_unavailable
    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
