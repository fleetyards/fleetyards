# frozen_string_literal: true

module Api
  module V1
    class CartListsController < ::Api::BaseController
      include ShoppingCartFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" }, unless: :user_signed_in?, only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?, except: %i[index show]
      before_action :check_shopping_cart_feature
      before_action :set_cart, only: %i[show update destroy clear]

      def index
        authorize! with: CartPolicy

        @carts = authorized_scope(Cart.all, with: CartPolicy)
          .left_joins(:cart_items)
          .select("carts.*, COUNT(cart_items.id) AS items_count")
          .group(:id)
          .order(:created_at)
      end

      # Where to buy what is on any of the user's lists, not just the active one.
      def show
        render_plan(strategy: params[:strategy])
      end

      def clear
        @cart.cart_items.delete_all

        render_plan
      end

      # A new list becomes the active one, since it is made to be filled.
      def create
        @cart = current_resource_owner.carts.new(name: params[:name])

        authorize! @cart, with: CartPolicy

        Cart.transaction do
          @cart.save!
          @cart.activate!
        end

        render :show, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("carts.create", errors: @cart.errors), status: :bad_request
      rescue ActiveRecord::RecordNotUnique
        # The same name saved by another request since the validation looked.
        @cart.errors.add(:name, :taken)
        render json: ValidationError.new("carts.create", errors: @cart.errors), status: :bad_request
      end

      def update
        Cart.transaction do
          @cart.update!(name: params[:name]) if params.key?(:name)
          @cart.activate! if ActiveModel::Type::Boolean.new.cast(params[:active])
        end

        render :show
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("carts.update", errors: @cart.errors), status: :bad_request
      rescue ActiveRecord::RecordNotUnique
        @cart.errors.add(:name, :taken)
        render json: ValidationError.new("carts.update", errors: @cart.errors), status: :bad_request
      end

      def destroy
        @cart.destroy_and_reactivate!

        render json: {success: true}
      end

      private def render_plan(strategy: nil)
        @trip_plan = Carts::TripPlan.new(authorized_scope(@cart.cart_items, with: CartItemPolicy), strategy:)

        render "api/v1/carts/show"
      end

      private def set_cart
        @cart = authorized_scope(Cart.all, with: CartPolicy).find(params[:id])

        authorize! @cart, with: CartPolicy
      end
    end
  end
end
