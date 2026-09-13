# frozen_string_literal: true

# `Contracts::Progress` matches deposits to a line by `(lower(name), category,
# unit)`, so two lines sharing that identity both claim the *same* entries: one
# delivery satisfies both, and the contract fulfils itself at half the goods.
#
# Lower(name) because the match is case-folded -- "Titanium" and "titanium" are
# one position to the ledger, and so have to be one line here.
class EnforceUniqueFleetContractItemIdentity < ActiveRecord::Migration[8.1]
  def change
    add_index :fleet_contract_items,
      "fleet_contract_id, lower(name), category, unit",
      unique: true,
      name: "index_fleet_contract_items_on_identity"
  end
end
