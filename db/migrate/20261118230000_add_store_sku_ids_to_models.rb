# frozen_string_literal: true

class AddStoreSkuIdsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :rsi_standalone_sku_id, :integer
    add_column :models, :rsi_upgrade_sku_id, :integer
  end
end
