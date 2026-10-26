# frozen_string_literal: true

module Api
  module V1
    class CartItemsController < ::Api::BaseController
      include ShoppingCartFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_shopping_cart_feature
      before_action :set_cart_item, only: %i[update destroy]

      # Adding an item already in the cart adds to its quantity.
      def create
        @cart_item = current_resource_owner.cart_items
          .find_or_initialize_by(item_type: params[:item_type], item_id: params[:item_id])

        authorize! @cart_item, with: CartItemPolicy

        added = params.fetch(:quantity, 1).to_i
        @cart_item.quantity = @cart_item.new_record? ? added : @cart_item.quantity + added

        if @cart_item.save
          render_cart(status: :created)
        else
          render json: ValidationError.new("cart_items.create", errors: @cart_item.errors), status: :bad_request
        end
      rescue ActiveRecord::RecordNotUnique
        # Two adds of the same item raced to insert it; the loser adds to the
        # row the winner created.
        retry
      end

      def update
        if @cart_item.update(cart_item_params)
          render_cart
        else
          render json: ValidationError.new("cart_items.update", errors: @cart_item.errors), status: :bad_request
        end
      end

      def destroy
        @cart_item.destroy!

        render_cart
      end

      private def set_cart_item
        @cart_item = authorized_scope(CartItem.all, with: CartItemPolicy).find(params[:id])

        authorize! @cart_item, with: CartItemPolicy
      end

      private def cart_item_params
        params.permit(:quantity, :item_price_id)
      end

      private def render_cart(status: :ok)
        @trip_plan = Carts::TripPlan.new(authorized_scope(CartItem.all, with: CartItemPolicy))

        render "api/v1/carts/show", status:
      end
    end
  end
end
