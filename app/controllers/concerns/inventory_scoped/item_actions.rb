# frozen_string_literal: true

module InventoryScoped
  # Ledger entries of a single inventory: deposits, withdrawals and the CSV
  # import that produces them in bulk.
  module ItemActions
    extend ActiveSupport::Concern
    include InventoryScoped

    QUERY_PARAMS = %i[name_cont name_eq unit_eq category_eq quality_gteq quality_lteq s].freeze

    included do
      after_action -> { pagination_header(:inventory_items) }, only: %i[index]
    end

    def index
      authorize! with: inventory_item_policy

      query_params = params.fetch(:q, {}).permit(*QUERY_PARAMS)
      normalize_sort_params(query_params)
      query_params["sorts"] = sorting_params(InventoryItem, query_params["sorts"])

      @q = inventory_items_scope.ransack(query_params)
      result = @q.result(distinct: true)

      @inventory_items = result_with_pagination(result, per_page(InventoryItem))
    end

    # Provisioning happens inside the transaction so a rejected deposit cannot
    # leave an empty inventory behind.
    def create
      ActiveRecord::Base.transaction do
        @inventory_item = provisioned_inventory.inventory_items.new(inventory_item_params)

        authorize! @inventory_item, with: inventory_item_policy

        raise ActiveRecord::Rollback unless @inventory_item.save
      end

      if @inventory_item.persisted?
        render :show, status: :created
      else
        render json: ValidationError.new("#{validation_error_scope}.create", errors: @inventory_item.errors),
          status: :bad_request
      end
    end

    def update
      authorize! @inventory_item, with: inventory_item_policy

      if @inventory_item.update(inventory_item_params)
        render :show
      else
        render json: ValidationError.new("#{validation_error_scope}.update", errors: @inventory_item.errors),
          status: :bad_request
      end
    end

    def destroy
      authorize! @inventory_item, with: inventory_item_policy

      unless @inventory_item.destroy
        render json: ValidationError.new("#{validation_error_scope}.destroy", errors: @inventory_item.errors),
          status: :bad_request
      end
    end

    # Provisioning happens inside the transaction for the same reason it does in
    # `create`: an import that lands nothing — an empty file, a malformed one, or
    # one whose every row is rejected — must not leave an inventory behind.
    def import
      authorize! inventory, with: inventory_policy, to: :update?

      file = params.require(:file)
      result = nil

      ActiveRecord::Base.transaction do
        importer = InventoryItemCsvImporter.new(provisioned_inventory, file, current_resource_owner)
        result = importer.call

        raise ActiveRecord::Rollback if result[:imported].to_i.zero?
      end

      render json: result, status: :ok
    end

    private def inventory_items_scope
      return InventoryItem.none unless inventory.persisted?

      inventory.inventory_items
    end

    private def inventory_item_params
      authorized(params, with: inventory_item_policy)
    end

    private def set_inventory_item
      @inventory_item = inventory.inventory_items.find(params[:id])
    end
  end
end
