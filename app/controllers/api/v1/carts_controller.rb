# frozen_string_literal: true

module Api
  module V1
    class CartsController < ::Api::BaseController
      include ShoppingCartFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" }, unless: :user_signed_in?, only: %i[show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?, only: %i[destroy]
      before_action :check_shopping_cart_feature

      def show
        authorize! with: CartItemPolicy, to: :index?

        @trip_plan = Carts::TripPlan.new(authorized_scope(CartItem.all, with: CartItemPolicy))
      end

      def destroy
        authorize! with: CartItemPolicy, to: :clear?

        scope = authorized_scope(CartItem.all, with: CartItemPolicy)
        scope.delete_all
        @trip_plan = Carts::TripPlan.new(scope)

        render :show
      end
    end
  end
end
