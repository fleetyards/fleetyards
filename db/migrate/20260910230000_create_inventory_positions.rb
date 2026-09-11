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
# **The backfill is here rather than in `db/data/`, and the column is `null:
# false` in the same migration, on purpose.** `.kamal/hooks/pre-deploy` runs
# `db:migrate` and then `data:migrate` before the new containers boot, so the
# previous release is still inserting entries throughout. Splitting this across
# two deploys does not protect that window: the new release reads stock through
# an inner join on the position, so an entry inserted without one is invisible
# to it whether the column is nullable or not. Nullable turns a deposit that
# 500s -- visible, retryable -- into one that reports success and then cannot be
# found. Doing it in one statement-run closes the window instead of choosing
# which way to fail in it.
#
# `name`, `category` and `unit` stay on the entries. The previous release reads
# them, `withdrawal_does_not_exceed_stock` still checks them, and they are
# dropped in their own deploy once nothing does.
class CreateInventoryPositions < ActiveRecord::Migration[8.1]
  KINDS = [
    {positions: "inventory_positions", entries: "inventory_items",
     key: "inventory_id", fk: "inventory_position_id"},
    {positions: "fleet_inventory_positions", entries: "fleet_inventory_items",
     key: "fleet_inventory_id", fk: "fleet_inventory_position_id"}
  ].freeze

  # The enum names the address has always been built from. Spelled out rather
  # than read from the model, because a migration has to keep running against
  # the schema of its own moment: these integers cannot change without a
  # migration of their own, while the labels are the model's business.
  CATEGORIES = {0 => "commodity", 1 => "component", 2 => "weapon", 3 => "equipment",
                4 => "ammunition", 5 => "consumable", 6 => "other"}.freeze
  UNITS = {0 => "scu", 1 => "units"}.freeze

  def up
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
    # one slug. This index is what forces the backfill below to disambiguate
    # rather than silently leaving one of them unreachable, as it is today.
    add_index :inventory_positions, [:inventory_id, :slug],
      unique: true, name: "index_inventory_positions_on_inventory_and_slug"
    add_index :fleet_inventory_positions, [:fleet_inventory_id, :slug],
      unique: true, name: "index_fleet_inventory_positions_on_inventory_and_slug"

    KINDS.each do |kind|
      add_column kind[:entries], kind[:fk], :uuid
      add_foreign_key kind[:entries], kind[:positions], column: kind[:fk], on_delete: :restrict
      add_index kind[:entries], kind[:fk]
    end

    up_only { KINDS.each { |kind| backfill(kind) } }

    KINDS.each { |kind| change_column_null kind[:entries], kind[:fk], false }
  end

  def down
    KINDS.each do |kind|
      remove_foreign_key kind[:entries], column: kind[:fk]
      remove_column kind[:entries], kind[:fk]
    end

    drop_table :fleet_inventory_positions
    drop_table :inventory_positions
  end

  # One position per distinct identity already in the ledger, then every entry
  # pointed at the one it belongs to. Read and written as raw SQL: an enum column
  # plucked through a model comes back as its label, and no model needs to be
  # loadable for a schema migration to run.
  private def backfill(kind)
    used = {}

    identities(kind).each do |(inventory_id, name, category, unit)|
      slug = free_slug(used, inventory_id, name, category, unit)
      id = insert_position(kind, inventory_id, name, category, unit, slug)

      point_entries(kind, id, inventory_id, name, category, unit)
    end
  end

  # Ordered, so which of two names competing for one address keeps the clean one
  # is the same in every environment rather than whatever the planner returned
  # first.
  private def identities(kind)
    select_rows(<<~SQL.squish)
      SELECT DISTINCT #{kind[:key]}, name, category, unit
      FROM #{kind[:entries]}
      WHERE #{kind[:fk]} IS NULL
      ORDER BY #{kind[:key]}, name, category, unit
    SQL
  end

  private def free_slug(used, inventory_id, name, category, unit)
    base = [name.to_s.parameterize.presence || "item", CATEGORIES.fetch(category), UNITS.fetch(unit)].join("--")
    taken = used[inventory_id] ||= Set.new

    candidate = base
    suffix = 1
    while taken.include?(candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    taken << candidate
    candidate
  end

  private def insert_position(kind, inventory_id, name, category, unit, slug)
    select_value(<<~SQL.squish)
      INSERT INTO #{kind[:positions]} (#{kind[:key]}, name, category, unit, slug, created_at, updated_at)
      VALUES (#{quote(inventory_id)}, #{quote(name)}, #{category.to_i}, #{unit.to_i}, #{quote(slug)}, NOW(), NOW())
      RETURNING id
    SQL
  end

  private def point_entries(kind, position_id, inventory_id, name, category, unit)
    execute(<<~SQL.squish)
      UPDATE #{kind[:entries]} SET #{kind[:fk]} = #{quote(position_id)}
      WHERE #{kind[:fk]} IS NULL
        AND #{kind[:key]} = #{quote(inventory_id)}
        AND name = #{quote(name)}
        AND category = #{category.to_i}
        AND unit = #{unit.to_i}
    SQL
  end

  private def quote(value) = connection.quote(value)

  private def select_value(sql) = connection.select_value(sql)

  private def select_rows(sql) = connection.select_rows(sql)
end
