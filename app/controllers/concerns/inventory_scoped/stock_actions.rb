# frozen_string_literal: true

module InventoryScoped
  # The ledger rolled up per stock position. Positions are addressed by a slug
  # derived from name, category and unit, so they survive being emptied out.
  module StockActions
    extend ActiveSupport::Concern
    include InventoryScoped

    def index
      authorize! inventory, with: inventory_policy, to: :show?

      @stock = inventory.persisted? ? inventory.current_stock : []
    end

    def show
      authorize! inventory, with: inventory_policy, to: :show?
    end

    def update
      authorize! inventory, with: inventory_policy, to: :update?

      change = inventory.update_stock_item(@stock_item, stock_item_params)

      unless change.valid?
        return render json: ValidationError.new("#{validation_error_scope}.update", errors: change.errors),
          status: :bad_request
      end

      @stock_item = inventory.stock_item(
        InventoryStockItem.slug_for(name: change.name, category: change.category, unit: change.unit)
      )

      render :show
    end

    def destroy
      authorize! inventory, with: inventory_policy, to: :update?

      inventory.destroy_stock_item(@stock_item)
    end

    private def stock_item_params
      params.permit(:name, :category, :unit).to_h.symbolize_keys
    end

    private def set_stock_item
      @stock_item = inventory.persisted? ? inventory.stock_item(params[:slug]) : nil

      not_found if @stock_item.blank?
    end
  end
end
