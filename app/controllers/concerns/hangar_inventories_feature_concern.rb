# frozen_string_literal: true

# Declare `before_action :check_hangar_inventories_feature` after the
# doorkeeper callbacks so unauthenticated requests still get a 401.
module HangarInventoriesFeatureConcern
  extend ActiveSupport::Concern

  private def check_hangar_inventories_feature
    return if feature_enabled?("hangar_inventories")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
