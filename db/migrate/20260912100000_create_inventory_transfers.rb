# frozen_string_literal: true

# Moving stock between two inventories as one recorded event.
#
# **One table, with four nullable inventory foreign keys.** A transfer may cross
# the two parallel schemas -- a user donating cargo to a fleet, a fleet issuing
# kit to a member -- so its source can be in `inventories` while its destination
# is in `fleet_inventories`. The two-table-per-level shape the rest of this
# subsystem uses has nowhere to put that. A polymorphic pair of columns would
# fit, but it gives up the foreign keys entirely, and four real ones are worth
# four nullable columns.
#
# **The four are `ON DELETE SET NULL`, and the invariants over them are model
# validations rather than check constraints.** `RESTRICT` was the first choice --
# a database-level backstop against destroying an inventory with goods still in
# flight -- and it is wrong: `User has_many :inventories, dependent: :destroy`,
# so it would make a single *completed* transfer block deleting that user
# forever. A finished transfer holds no goods and must not restrain anything,
# and a foreign key cannot tell the two apart. What can is the model, and
# `InventoryStock` refuses to destroy an inventory whose entries belong to a
# pending transfer -- with an error naming it, which is what a person needs
# anyway. The keys here only keep ids from dangling.
#
# **No line table.** A transfer's lines are its ledger entries: the withdrawals
# it wrote on the source, and later the deposits it wrote at the destination.
# Storing name/category/unit/quantity a second time would duplicate the entry's
# own column list, with the drift that implies. Which side an entry is on is
# read from the pair it forms with the transfer -- source+withdrawal dispatched,
# destination+deposit delivered, source+deposit returned -- which is unambiguous
# because a check constraint stops the two ever being the same row.
class CreateInventoryTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_transfers, id: :uuid do |t|
      # One source, and one destination once it is known. A destination stays
      # null while a cross-party transfer waits for its recipient to name one.
      t.references :source_inventory, type: :uuid, null: true,
        foreign_key: {to_table: :inventories, on_delete: :nullify}
      t.references :source_fleet_inventory, type: :uuid, null: true,
        foreign_key: {to_table: :fleet_inventories, on_delete: :nullify}
      t.references :destination_inventory, type: :uuid, null: true,
        foreign_key: {to_table: :inventories, on_delete: :nullify}
      t.references :destination_fleet_inventory, type: :uuid, null: true,
        foreign_key: {to_table: :fleet_inventories, on_delete: :nullify}

      # Who it is addressed to, when the sender was not allowed to name an
      # inventory directly. Null on an immediate transfer.
      t.references :recipient, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}
      t.references :recipient_fleet, type: :uuid, null: true,
        foreign_key: {to_table: :fleets, on_delete: :nullify}

      # Nullable for the same reason as the four above: a deleted account must
      # not take a fleet's transfer history with it, and must not be undeletable
      # because of it.
      t.references :initiated_by, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}
      t.references :resolved_by, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}

      t.string :aasm_state, null: false, default: "pending"
      t.text :note

      t.datetime :expires_at
      t.datetime :completed_at
      t.datetime :declined_at
      t.datetime :cancelled_at
      t.datetime :expired_at

      t.timestamps
    end

    # These two survive a SET NULL -- nulling a column can only make "at most
    # one" more true -- so they stay in the database. "Exactly one source" and
    # "has a target" cannot, and live on the model instead.
    add_check_constraint :inventory_transfers,
      "(destination_inventory_id IS NOT NULL)::int + (destination_fleet_inventory_id IS NOT NULL)::int <= 1",
      name: "inventory_transfers_at_most_one_destination"

    add_check_constraint :inventory_transfers,
      "(recipient_id IS NOT NULL)::int + (recipient_fleet_id IS NOT NULL)::int <= 1",
      name: "inventory_transfers_at_most_one_recipient"

    # What makes the source/destination reading of an entry unambiguous.
    add_check_constraint :inventory_transfers,
      "destination_inventory_id IS NULL OR destination_inventory_id <> source_inventory_id",
      name: "inventory_transfers_not_to_itself"

    add_check_constraint :inventory_transfers,
      "destination_fleet_inventory_id IS NULL OR destination_fleet_inventory_id <> source_fleet_inventory_id",
      name: "inventory_transfers_not_to_itself_fleet"

    # The inbox, and the per-recipient cap that keeps a stranger from filling
    # one. Partial, because only pending rows are ever counted this way.
    add_index :inventory_transfers, :recipient_id,
      where: "aasm_state = 'pending'",
      name: "index_inventory_transfers_on_pending_recipient"
    add_index :inventory_transfers, :recipient_fleet_id,
      where: "aasm_state = 'pending'",
      name: "index_inventory_transfers_on_pending_recipient_fleet"

    # What the expiry sweeper scans.
    add_index :inventory_transfers, :expires_at, where: "aasm_state = 'pending'",
      name: "index_inventory_transfers_on_pending_expires_at"

    add_column :inventory_items, :inventory_transfer_id, :uuid
    add_foreign_key :inventory_items, :inventory_transfers,
      column: :inventory_transfer_id, on_delete: :nullify
    add_index :inventory_items, :inventory_transfer_id

    add_column :fleet_inventory_items, :inventory_transfer_id, :uuid
    add_foreign_key :fleet_inventory_items, :inventory_transfers,
      column: :inventory_transfer_id, on_delete: :nullify
    add_index :fleet_inventory_items, :inventory_transfer_id
  end
end
