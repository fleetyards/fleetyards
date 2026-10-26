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
        @cart_item = add_item(item_type: params[:item_type], item_id: params[:item_id], added: params.fetch(:quantity, 1).to_i)

        if @cart_item.errors.empty?
          render_cart(status: :created)
        else
          render json: ValidationError.new("cart_items.create", errors: @cart_item.errors), status: :bad_request
        end
      rescue ActiveRecord::RecordNotUnique
        # Two adds of the same item raced to insert it; the loser adds to the
        # row the winner created.
        retry
      end

      # All or nothing, so a loadout never lands in the cart half added.
      def bulk_create
        failed = nil

        ActiveRecord::Base.transaction do
          bulk_items.each do |(item_type, item_id), added|
            cart_item = add_item(item_type:, item_id:, added:)
            next if cart_item.errors.empty?

            failed = cart_item
            raise ActiveRecord::Rollback
          end
        end

        if failed
          render json: ValidationError.new("cart_items.create", errors: failed.errors), status: :bad_request
        else
          render_cart(status: :created)
        end
      rescue ActiveRecord::RecordNotUnique
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

      private def add_item(item_type:, item_id:, added:)
        cart_item = target_cart.cart_items.find_or_initialize_by(item_type:, item_id:)

        authorize! cart_item, with: CartItemPolicy, to: :create?

        if cart_item.new_record?
          cart_item.quantity = added
          cart_item.save
        else
          # Locked, so two adds of an item already in the cart both count.
          cart_item.with_lock do
            cart_item.quantity += added
            cart_item.save
          end
        end

        cart_item
      end

      # The same item twice in one request is one line with both quantities.
      private def bulk_items
        params.require(:items).map { |entry| entry.permit(:item_type, :item_id, :quantity) }
          .group_by { |entry| [entry[:item_type], entry[:item_id]] }
          .transform_values { |entries| entries.sum { |entry| entry.fetch(:quantity, 1).to_i } }
      end

      # The active list unless the request names another, which stays inactive.
      private def target_cart
        @target_cart ||= if params[:cart_id].present?
          authorized_scope(Cart.all, with: CartPolicy).find(params[:cart_id])
        else
          Cart.active_for!(current_resource_owner)
        end
      end

      private def render_cart(status: :ok)
        @cart = @cart_item&.cart || target_cart
        @trip_plan = Carts::TripPlan.new(authorized_scope(@cart.cart_items, with: CartItemPolicy))

        render "api/v1/carts/show", status:
      end
    end
  end
end
