# frozen_string_literal: true

# A job a fleet posts for its members: haul goods between two of its
# inventories, buy goods and bring them in, or craft them to a required quality.
#
# **No progress column.** What has been delivered is a sum over the ledger
# entries a linked transfer wrote at the destination, and those only exist once
# a transfer was accepted. A stored copy would be exactly the derived total
# `inventory_positions` refuses to store, with the extra failure mode that a
# contract could then be advanced by writing to it rather than by moving goods.
#
# **Both inventory keys are `ON DELETE SET NULL`.** The reasoning
# `CreateInventoryTransfers` was corrected to, unchanged: a finished contract
# holds nothing, and a foreign key cannot tell it from a running one, so
# `RESTRICT` would make an inventory named by a year-old contract undeletable
# forever. The model is where a running contract produces a readable error.
class CreateFleetContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_contracts, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false,
        foreign_key: {to_table: :fleets}
      t.references :created_by, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}

      t.string :title, null: false
      t.string :slug, null: false
      t.text :description

      t.integer :kind, null: false, default: 0

      # Where the goods come from, for a transport contract only, and where they
      # have to end up, for all three.
      t.references :source_fleet_inventory, type: :uuid, null: true,
        foreign_key: {to_table: :fleet_inventories, on_delete: :nullify}
      t.references :destination_fleet_inventory, type: :uuid, null: true,
        foreign_key: {to_table: :fleet_inventories, on_delete: :nullify}

      # decimal(15, 2) with no currency column, matching item_prices.price and
      # the payout ledger this settles on. aUEC is the only currency there is,
      # and its name lives in the `number.units.uec` translation.
      t.decimal :reward, precision: 15, scale: 2, null: false, default: 0
      t.boolean :reimburse_expenses, null: false, default: true

      # How many accepted contractors the lead may take on. Null is unlimited.
      t.integer :crew_limit

      t.datetime :deadline

      t.string :aasm_state, null: false, default: "draft"

      t.datetime :published_at
      t.datetime :claimed_at
      t.datetime :fulfilled_at
      t.datetime :cancelled_at
      t.datetime :expired_at

      t.timestamps
    end

    add_index :fleet_contracts, [:fleet_id, :slug], unique: true
    add_index :fleet_contracts, [:fleet_id, :aasm_state]
    add_index :fleet_contracts, [:fleet_id, :kind]

    # A transport contract is the only kind with somewhere to collect from, and
    # it is the one kind that cannot do without it -- so the column is exactly
    # as nullable as the kind makes it.
    add_check_constraint :fleet_contracts,
      "(kind = 0 AND source_fleet_inventory_id IS NOT NULL) OR (kind <> 0 AND source_fleet_inventory_id IS NULL)",
      name: "fleet_contracts_source_only_for_transport"

    add_check_constraint :fleet_contracts, "reward >= 0",
      name: "fleet_contracts_reward_not_negative"

    add_check_constraint :fleet_contracts, "crew_limit IS NULL OR crew_limit > 0",
      name: "fleet_contracts_crew_limit_positive"
  end
end
