# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetInventoriesController < ::Admin::Api::BaseController
        before_action :set_fleet
        before_action :set_inventory, only: %i[show]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          @inventories = @fleet.fleet_inventories
            .includes(:manager)
            .order(name: :asc)
            .page(params[:page])
            .per(per_page(FleetInventory))
        end

        def show
        end

        private def set_fleet
          @fleet = Fleet.find(params[:fleet_id])

          authorize! @fleet, with: ::Admin::FleetPolicy
        end

        private def set_inventory
          @inventory = @fleet.fleet_inventories.includes(:manager).find(params[:id])
        end
      end
    end
  end
end
