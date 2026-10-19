# frozen_string_literal: true

class AddCraftedToFleetContractItems < ActiveRecord::Migration[8.1]
  def change
    # Refused rather than nullified: a line that lost its recipe would quietly
    # become a plain one and accept any part of that name.
    add_reference :fleet_contract_items, :crafted_blueprint, type: :uuid, index: true,
      foreign_key: {to_table: :blueprints, on_delete: :restrict}
    add_column :fleet_contract_items, :crafted_qualities, :jsonb
  end
end
