# frozen_string_literal: true

module Api
  module V1
    class HangarInventoryItemsController < ::Api::BaseController
      include HangarInventoriesFeatureConcern
      include InventoryScoped::ItemActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy import add_pledge_items]

      before_action :check_hangar_inventories_feature
      before_action :set_inventory_item, only: %i[update destroy]

      # Deposits each given ship component or piece of gear once. An item one of
      # the user's deposits already came from is skipped, so adding a selection
      # twice never doubles the stock. The items are locked while they are
      # added, so two requests cannot both find one not yet added.
      def add_pledge_items
        authorize! provisioned_inventory.inventory_items.new, to: :create?, with: inventory_item_policy

        added = []
        skipped = []

        ActiveRecord::Base.transaction do
          pledge_items = current_resource_owner.hangar_pledge_items.for_inventory
            .where(id: Array(params[:pledge_item_ids]))
            .includes(:catalogue_component, :catalogue_equipment)
            .lock

          deposited = HangarPledgeItem.deposits_for(current_resource_owner, pledge_items)
          added, skipped = pledge_items.partition { |item| !deposited.key?(item.source_key) }

          added.each { |item| provisioned_inventory.inventory_items.create!(item.inventory_entry_attributes) }
        end

        render json: {addedPledgeItemIds: added.map(&:id), skippedPledgeItemIds: skipped.map(&:id)}
      rescue ActiveRecord::RecordInvalid => error
        render json: ValidationError.new("#{validation_error_scope}.add_pledge_items", errors: error.record.errors),
          status: :bad_request
      end

      private def inventory
        @inventory ||= current_resource_owner.inventories.addressable_by_slug.find_by!(slug: params[:hangar_inventory_slug])
      end

      private def inventory_policy
        HangarInventoryPolicy
      end

      private def inventory_item_policy
        HangarInventoryItemPolicy
      end

      private def validation_error_scope
        "hangar_inventory_items"
      end
    end
  end
end
