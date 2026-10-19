# frozen_string_literal: true

class AddCraftedToFleetContractItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :fleet_contract_items, :crafted_blueprint, type: :uuid, index: true,
      foreign_key: {to_table: :blueprints, on_delete: :nullify}
    add_column :fleet_contract_items, :crafted_qualities, :jsonb
  end
end
