# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetInventoryItemsController < ::Admin::Api::BaseController
        before_action :set_inventory
        before_action :set_item, only: %i[show]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          @items = @inventory.fleet_inventory_items
            .order(created_at: :desc)
            .page(params[:page])
            .per(per_page(FleetInventoryItem))
        end

        def show
        end

        # The fleet carries the permission, the same walk `VersionedItem` makes
        # to decide who may read one of these entries' versions.
        private def set_inventory
          fleet = Fleet.find(params[:fleet_id])

          authorize! fleet, with: ::Admin::FleetPolicy

          @inventory = fleet.fleet_inventories.find(params[:fleet_inventory_id])
        end

        private def set_item
          @item = @inventory.fleet_inventory_items.find(params[:id])
        end
      end
    end
  end
end
