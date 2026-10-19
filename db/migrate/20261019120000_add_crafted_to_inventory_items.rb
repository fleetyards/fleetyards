# frozen_string_literal: true

class AddCraftedToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    %i[inventory_items fleet_inventory_items].each do |table|
      add_reference table, :crafted_blueprint, type: :uuid, index: true,
        foreign_key: {to_table: :blueprints, on_delete: :nullify}
      add_column table, :crafted_qualities, :jsonb
    end
  end
end
