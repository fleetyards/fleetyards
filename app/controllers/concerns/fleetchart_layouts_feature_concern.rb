# frozen_string_literal: true

# Declare `before_action :check_fleetchart_layouts_feature` after the doorkeeper
# callbacks so unauthenticated requests still get a 401.
module FleetchartLayoutsFeatureConcern
  extend ActiveSupport::Concern

  private def check_fleetchart_layouts_feature
    return if feature_enabled?("fleetchart_layouts")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
