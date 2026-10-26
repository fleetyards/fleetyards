# frozen_string_literal: true

module Api
  module V1
    class FleetShoppingListsController < ::Api::BaseController
      include ShoppingCartFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show copy]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]
      # Publishing reads the user's own list, and copying writes one.
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        if: -> { params[:cart_id].present? },
        only: %i[create update]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[copy]

      before_action :check_shopping_cart_feature
      before_action :set_fleet
      before_action :set_fleet_shopping_list, only: %i[show update destroy copy]

      def index
        authorize! with: FleetShoppingListPolicy, context: {fleet: @fleet}

        @fleet_shopping_lists = authorized_scope(@fleet.fleet_shopping_lists, with: FleetShoppingListPolicy,
          context: {fleet: @fleet})
          .includes(fleet_squadrons: {icon_attachment: :blob})
          .left_joins(:fleet_shopping_list_items)
          .select("fleet_shopping_lists.*, COUNT(fleet_shopping_list_items.id) AS lines_count, " \
            "COALESCE(SUM(fleet_shopping_list_items.quantity), 0) AS items_count")
          .group(:id)
          .order(:name)
      end

      def show
        authorize! @fleet_shopping_list

        @trip_plan = Carts::TripPlan.new(@fleet_shopping_list.fleet_shopping_list_items)
      end

      def create
        @fleet_shopping_list = @fleet.fleet_shopping_lists.new(fleet_shopping_list_params)

        authorize! @fleet_shopping_list

        cart = own_cart!
        return render_empty_source("fleet_shopping_lists.create") if cart.cart_items.none?

        FleetShoppingList.transaction do
          @fleet_shopping_list.save!
          @fleet_shopping_list.replace_items_from!(cart)
        end

        render :summary, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("fleet_shopping_lists.create", errors: @fleet_shopping_list.errors), status: :bad_request
      rescue ActiveRecord::RecordNotUnique
        @fleet_shopping_list.errors.add(:name, :taken)
        render json: ValidationError.new("fleet_shopping_lists.create", errors: @fleet_shopping_list.errors), status: :bad_request
      end

      # Naming one of the user's own lists replaces every line with that
      # list's, which is how a published list is kept up to date. Authorized
      # again on the new attributes, inside the transaction, since assigning
      # squadrons to a saved record writes them at once.
      def update
        authorize! @fleet_shopping_list

        cart = own_cart! if params[:cart_id].present?
        return render_empty_source("fleet_shopping_lists.update") if cart&.cart_items&.none?

        FleetShoppingList.transaction do
          @fleet_shopping_list.assign_attributes(fleet_shopping_list_params)
          authorize! @fleet_shopping_list
          @fleet_shopping_list.save!
          @fleet_shopping_list.replace_items_from!(cart) if cart
        end

        render :summary
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("fleet_shopping_lists.update", errors: @fleet_shopping_list.errors), status: :bad_request
      rescue ActiveRecord::RecordNotUnique
        @fleet_shopping_list.errors.add(:name, :taken)
        render json: ValidationError.new("fleet_shopping_lists.update", errors: @fleet_shopping_list.errors), status: :bad_request
      end

      def destroy
        authorize! @fleet_shopping_list

        if @fleet_shopping_list.destroy
          render json: {success: true}
        else
          render json: ValidationError.new("fleet_shopping_lists.destroy", errors: @fleet_shopping_list.errors), status: :bad_request
        end
      end

      # Into one of the user's own lists, or a new one named after this list,
      # which becomes the active one as any new list does.
      def copy
        authorize! @fleet_shopping_list

        lines = @fleet_shopping_list.copyable_items

        if lines.empty?
          @fleet_shopping_list.errors.add(:base, :nothing_to_copy)
          return render json: ValidationError.new("fleet_shopping_lists.copy", errors: @fleet_shopping_list.errors), status: :bad_request
        end

        @cart = params[:cart_id].present? ? own_cart! : nil

        Cart.transaction do
          @cart ||= new_cart_for_copy
          @fleet_shopping_list.copy_items_to!(@cart, lines)
        end

        @trip_plan = Carts::TripPlan.new(authorized_scope(@cart.cart_items, with: CartItemPolicy))

        render "api/v1/carts/show"
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("fleet_shopping_lists.copy", errors: e.record.errors), status: :bad_request
      rescue ActiveRecord::RecordNotUnique
        # The same name taken by a second copy since `unused_name` looked.
        @fleet_shopping_list.errors.add(:base, :copy_conflict)
        render json: ValidationError.new("fleet_shopping_lists.copy", errors: @fleet_shopping_list.errors), status: :bad_request
      end

      private def render_empty_source(code)
        @fleet_shopping_list.errors.add(:base, :empty_source)
        render json: ValidationError.new(code, errors: @fleet_shopping_list.errors), status: :bad_request
      end

      private def new_cart_for_copy
        cart = current_resource_owner.carts.create!(name: Cart.unused_name(current_resource_owner, @fleet_shopping_list.name))
        cart.activate!
        cart
      end

      private def own_cart!
        authorized_scope(Cart.all, with: CartPolicy).find(params[:cart_id])
      end

      private def fleet_shopping_list_params
        authorized(params, with: FleetShoppingListPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      # Through the visible scope, so a list hidden from this member answers
      # 404 rather than confirming it exists.
      private def set_fleet_shopping_list
        @fleet_shopping_list = authorized_scope(@fleet.fleet_shopping_lists, with: FleetShoppingListPolicy,
          context: {fleet: @fleet}, as: :visible).find(params[:id])
      end
    end
  end
end
