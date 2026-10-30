# frozen_string_literal: true

module Api
  module V1
    class CartsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" }, unless: :user_signed_in?, only: %i[show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?, only: %i[destroy]

      def show
        authorize! with: CartItemPolicy, to: :index?

        @trip_plan = Carts::TripPlan.new(active_cart_items, strategy: params[:strategy])
      end

      def destroy
        authorize! with: CartItemPolicy, to: :clear?

        scope = active_cart_items
        scope.delete_all
        @trip_plan = Carts::TripPlan.new(scope)

        render :show
      end

      private def active_cart_items
        @cart = Cart.active_for(current_resource_owner)
        return CartItem.none unless @cart

        authorized_scope(@cart.cart_items, with: CartItemPolicy)
      end
    end
  end
end
