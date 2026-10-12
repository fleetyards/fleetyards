# frozen_string_literal: true

# Declare `before_action :check_vehicle_overview_feature` after the doorkeeper
# callbacks so unauthenticated requests still get a 401.
module VehicleOverviewFeatureConcern
  extend ActiveSupport::Concern

  private def check_vehicle_overview_feature
    return if feature_enabled?("vehicle_overview")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
