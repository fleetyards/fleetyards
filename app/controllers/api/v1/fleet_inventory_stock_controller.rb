# frozen_string_literal: true

module Api
  module V1
    class FleetInventoryStockController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?

      before_action :set_fleet
      before_action :set_fleet_inventory

      def index
        authorize! with: FleetInventoryItemPolicy, context: {fleet: @fleet}

        @stock = @fleet_inventory.current_stock
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_inventory
        @fleet_inventory = @fleet.fleet_inventories.find_by!(slug: params[:fleet_inventory_slug])
      end
    end
  end
end
