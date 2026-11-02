# frozen_string_literal: true

# Declare `before_action :check_dressing_room_feature` after the doorkeeper
# callbacks so unauthenticated requests still get a 401.
module DressingRoomFeatureConcern
  extend ActiveSupport::Concern

  private def check_dressing_room_feature
    return if feature_enabled?("dressing_room")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
