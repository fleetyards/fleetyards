# frozen_string_literal: true

# A contract may ask for one part plain and crafted, or crafted at two sets of
# grades or by two match rules, so how a line is crafted is part of what makes
# it unique. Coalesced because a unique index treats NULLs as distinct, which
# would let two plain lines for one part through again; the match rule only
# counts for a crafted line, as a plain one's grade still makes no difference.
class WidenFleetContractItemIdentity < ActiveRecord::Migration[8.1]
  OLD = "fleet_contract_id, lower(name), category, unit"

  NEW = "fleet_contract_id, lower(name), category, unit, " \
    "COALESCE(crafted_blueprint_id, '00000000-0000-0000-0000-000000000000'::uuid), " \
    "COALESCE(crafted_qualities, '{}'::jsonb), " \
    "(CASE WHEN crafted_blueprint_id IS NULL THEN 0 ELSE quality_match END)"

  def up
    remove_index :fleet_contract_items, name: "index_fleet_contract_items_on_identity"
    add_index :fleet_contract_items, NEW, unique: true, name: "index_fleet_contract_items_on_identity"
  end

  def down
    remove_index :fleet_contract_items, name: "index_fleet_contract_items_on_identity"
    add_index :fleet_contract_items, OLD, unique: true, name: "index_fleet_contract_items_on_identity"
  end
end
