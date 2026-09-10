# frozen_string_literal: true

# A stock position, which until now had no row.
#
# A position was derived -- `GROUP BY name, category, unit` over the ledger
# entries -- so its identity was a mutable label, and renaming one entry moved
# that entry into a different group. Withdrawals left behind ended up in a group
# with no deposits, at a negative net that `current_stock` hides. #4844 recorded
# the rename and #4849 refused the split; this removes the cause.
#
# Two tables rather than one polymorphic table, because that is how everything
# about inventories is already shaped here: `inventories`/`fleet_inventories`,
# `inventory_items`/`fleet_inventory_items`, with the shared behaviour in a
# concern. It also keeps the foreign key enforced by the database.
#
# `name`, `category` and `unit` stay on the entries for now: the previous release
# is still serving writes while this migration runs, and the backfill reads them.
# They are dropped in a later deploy, once nothing reads them.
class CreateInventoryPositions < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_positions, id: :uuid do |t|
      # Cascade: a position is a grouping inside one inventory and means nothing
      # without it. The entries cascade from the same place already.
      t.references :inventory, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.integer :unit, null: false, default: 0

      # `name--category--unit`, the address three published endpoints already
      # use. Kept so every existing position URL keeps resolving.
      t.string :slug, null: false

      t.timestamps
    end

    create_table :fleet_inventory_positions, id: :uuid do |t|
      t.references :fleet_inventory, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.integer :unit, null: false, default: 0
      t.string :slug, null: false

      t.timestamps
    end

    # The identity a position *is*. Unenforced until now -- there was no unique
    # index on the triple, so nothing stopped two of them existing.
    add_index :inventory_positions, [:inventory_id, :name, :category, :unit],
      unique: true, name: "index_inventory_positions_on_inventory_and_identity"
    add_index :fleet_inventory_positions, [:fleet_inventory_id, :name, :category, :unit],
      unique: true, name: "index_fleet_inventory_positions_on_inventory_and_identity"

    # Addressability, which is narrower than identity: the slug parameterizes the
    # name, so "Med Pens" and "med-pens" are two positions that would generate
    # one slug. This index is what forces the backfill to disambiguate rather
    # than silently leaving one of them unreachable, which is the behaviour today.
    add_index :inventory_positions, [:inventory_id, :slug],
      unique: true, name: "index_inventory_positions_on_inventory_and_slug"
    add_index :fleet_inventory_positions, [:fleet_inventory_id, :slug],
      unique: true, name: "index_fleet_inventory_positions_on_inventory_and_slug"

    # Nullable, and it has to be: `.kamal/hooks/pre-deploy` migrates before the
    # new containers boot, so the previous release is still inserting entries
    # that know nothing about this column. `null: false` follows in its own
    # deploy, once the backfill has run everywhere.
    add_reference :inventory_items, :inventory_position, type: :uuid, null: true,
      foreign_key: {on_delete: :restrict}
    add_reference :fleet_inventory_items, :fleet_inventory_position, type: :uuid, null: true,
      foreign_key: {on_delete: :restrict}
  end
end
