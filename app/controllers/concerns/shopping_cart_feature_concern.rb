# frozen_string_literal: true

# Declare `before_action :check_shopping_cart_feature` after the doorkeeper
# callbacks so unauthenticated requests still get a 401.
module ShoppingCartFeatureConcern
  extend ActiveSupport::Concern

  private def check_shopping_cart_feature
    return if feature_enabled?("shopping_cart")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
