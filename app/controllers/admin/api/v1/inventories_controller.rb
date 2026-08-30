# frozen_string_literal: true

module Admin
  module Api
    module V1
      class InventoriesController < ::Admin::Api::BaseController
        before_action :set_user
        before_action :set_inventory, only: %i[show]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          @inventories = @user.inventories
            .order(name: :asc)
            .page(params[:page])
            .per(per_page(Inventory))
        end

        def show
        end

        # `holder` is polymorphic, but a user is the only thing that holds one
        # today, and the user's policy is what `VersionedItem` walks to as well.
        private def set_user
          @user = User.find(params[:user_id])

          authorize! @user, with: ::Admin::UserPolicy
        end

        private def set_inventory
          @inventory = @user.inventories.find(params[:id])
        end
      end
    end
  end
end
