# frozen_string_literal: true

# Declare `before_action :check_raffles_feature` after the authentication
# callbacks so unauthenticated requests still get a 401.
module RafflesFeatureConcern
  extend ActiveSupport::Concern

  private def check_raffles_feature
    return if feature_enabled?("raffles")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
