# frozen_string_literal: true

# Declare `before_action :check_hangar_planner_feature` after the doorkeeper
# callbacks so unauthenticated requests still get a 401.
module HangarPlannerFeatureConcern
  extend ActiveSupport::Concern

  private def check_hangar_planner_feature
    return if feature_enabled?("hangar_planner")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
