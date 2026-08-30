# frozen_string_literal: true

module Admin
  module Api
    module V1
      class InventoryItemsController < ::Admin::Api::BaseController
        before_action :set_inventory
        before_action :set_item, only: %i[show]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          @items = @inventory.inventory_items
            .order(created_at: :desc)
            .page(params[:page])
            .per(per_page(InventoryItem))
        end

        def show
        end

        private def set_inventory
          user = User.find(params[:user_id])

          authorize! user, with: ::Admin::UserPolicy

          @inventory = user.inventories.find(params[:inventory_id])
        end

        private def set_item
          @item = @inventory.inventory_items.find(params[:id])
        end
      end
    end
  end
end
