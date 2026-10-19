# frozen_string_literal: true

class AddCraftedToFleetContractItems < ActiveRecord::Migration[8.1]
  def change
    # Refused rather than nullified: a line that lost its recipe would quietly
    # become a plain one and accept any part of that name.
    add_reference :fleet_contract_items, :crafted_blueprint, type: :uuid, index: true,
      foreign_key: {to_table: :blueprints, on_delete: :restrict}
    add_column :fleet_contract_items, :crafted_qualities, :jsonb

    # A contract may ask for one part plain and crafted, or crafted at two sets
    # of grades, so how it is crafted is part of what makes a line unique.
    # Coalesced because a unique index treats NULLs as distinct, which would
    # let two plain lines for one part through again.
    remove_index :fleet_contract_items,
      "fleet_contract_id, lower(name), category, unit",
      unique: true,
      name: "index_fleet_contract_items_on_identity"
    add_index :fleet_contract_items,
      "fleet_contract_id, lower(name), category, unit, " \
      "COALESCE(crafted_blueprint_id, '00000000-0000-0000-0000-000000000000'::uuid), " \
      "COALESCE(crafted_qualities, '{}'::jsonb)",
      unique: true,
      name: "index_fleet_contract_items_on_identity"
  end
end
