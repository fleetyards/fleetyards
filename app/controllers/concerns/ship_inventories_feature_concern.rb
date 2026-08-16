# frozen_string_literal: true

# Declare `before_action :check_ship_inventories_feature` after the
# doorkeeper callbacks so unauthenticated requests still get a 401.
module ShipInventoriesFeatureConcern
  extend ActiveSupport::Concern

  private def check_ship_inventories_feature
    return if ship_inventories_enabled?

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end

  # Hangar endpoints stay open while the flag is off; they just stop reporting
  # the inventories that only exist because a ship provisioned one.
  private def ship_inventories_enabled?
    feature_enabled?("ship_inventories")
  end
end
