# frozen_string_literal: true

# Who a contract-linked transfer's goods came from, recorded when the link is
# made.
#
# `Contracts::Progress` used to derive this from the transfer's source
# inventory, which is right until that inventory is deleted -- the key is
# `ON DELETE SET NULL`, so a finished transfer loses the only record of whose
# goods it moved, and with it the contractor's share of the reward. Deriving it
# from `initiated_by` instead is worse: an officer who dispatched on a member's
# behalf would take their share.
#
# Attribution is certain at exactly one moment -- when the transfer is created
# and its source is still there -- so that is when it is written down. Only
# meaningful for a transfer that names a contract, which is why it sits beside
# `fleet_contract_id` rather than describing transfers in general.
class AddFleetContractContributorToInventoryTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_transfers, :fleet_contract_contributor_id, :uuid
    add_foreign_key :inventory_transfers, :users,
      column: :fleet_contract_contributor_id, on_delete: :nullify
    add_index :inventory_transfers, :fleet_contract_contributor_id,
      where: "fleet_contract_contributor_id IS NOT NULL",
      name: "index_inventory_transfers_on_contract_contributor"
  end
end
