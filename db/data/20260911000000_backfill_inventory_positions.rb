# frozen_string_literal: true

# Creates one position per distinct identity already in the ledger, and points
# every entry at the one it belongs to.
#
# A data migration rather than a maintenance task, and the threshold is the one
# `BackfillHardpointBuildsTask` records: `bin/deploy-release` runs `data:migrate`
# inside the Kamal pre-deploy hook, so a long backfill blocks every deploy behind
# it and a retried hook re-scans the whole table. That task walks 22,561 rows.
# This walks 12 in production today -- 1 `inventory_item` and 11
# `fleet_inventory_items` -- so it belongs here.
#
# Re-runnable: an entry that already points at a position is left alone, so a
# retried pre-deploy hook is harmless.
class BackfillInventoryPositions < ActiveRecord::Migration[8.1]
  # Its own copy on purpose, per the convention the component backfill records: a
  # migration has to keep running against the schema of its own moment, not
  # against `InventoryStockItem.slug_for` as that later becomes.
  def self.slug_for(name, category, unit)
    [name.to_s.parameterize.presence || "item", category, unit].join("--")
  end

  # The enum names the slug has always been built from, mapped from the stored
  # integers. Copied for the same reason `slug_for` is.
  CATEGORIES = {0 => "commodity", 1 => "component", 2 => "weapon", 3 => "equipment",
                4 => "ammunition", 5 => "consumable", 6 => "other"}.freeze
  UNITS = {0 => "scu", 1 => "units"}.freeze

  KINDS = [
    {entry: "InventoryItem", position: "InventoryPosition", table: "inventory_items",
     key: :inventory_id, fk: :inventory_position_id},
    {entry: "FleetInventoryItem", position: "FleetInventoryPosition", table: "fleet_inventory_items",
     key: :fleet_inventory_id, fk: :fleet_inventory_position_id}
  ].freeze

  def up
    KINDS.each { |kind| backfill(kind) }
  end

  def down
    KINDS.each do |kind|
      kind[:entry].constantize.update_all(kind[:fk] => nil)
      kind[:position].constantize.delete_all
    end
  end

  private def backfill(kind)
    entries = kind[:entry].constantize
    positions = kind[:position].constantize

    identities(entries, kind).each do |(inventory_id, name, category, unit)|
      position = positions.find_by(kind[:key] => inventory_id, :name => name, :category => category, :unit => unit)
      position ||= positions.create!(
        kind[:key] => inventory_id, :name => name, :category => category, :unit => unit,
        :slug => free_slug(positions, kind, inventory_id, name, category, unit)
      )

      entries
        .where(kind[:fk] => nil)
        .where(kind[:key] => inventory_id, :name => name, :category => category, :unit => unit)
        .update_all(kind[:fk] => position.id)
    end
  end

  # Ordered, so which of two names competing for one slug keeps the clean one is
  # the same in every environment and on a re-run rather than whatever the
  # planner returned first.
  #
  # Read as raw rows rather than through `pluck`, which casts an enum column to
  # its label. Integers are what this migration should see: the labels are the
  # model's business and can be renamed later, while the stored values cannot
  # change without a migration of their own.
  private def identities(_entries, kind)
    connection.select_rows(<<~SQL.squish)
      SELECT DISTINCT #{kind[:key]}, name, category, unit
      FROM #{kind[:table]}
      WHERE #{kind[:fk]} IS NULL
      ORDER BY #{kind[:key]}, name, category, unit
    SQL
  end

  # The slug parameterizes the name, so "Med Pens" and "med-pens" are two
  # identities competing for one address. Today the loser is unreachable --
  # whichever row `detect` hits first answers for both. The suffix is what makes
  # it addressable, and the unique index is what would otherwise stop the
  # backfill dead here.
  private def free_slug(positions, kind, inventory_id, name, category, unit)
    base = self.class.slug_for(name, category_name(category), unit_name(unit))
    candidate = base
    suffix = 1

    while positions.exists?(kind[:key] => inventory_id, :slug => candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    candidate
  end

  private def category_name(value) = CATEGORIES.fetch(value)

  private def unit_name(value) = UNITS.fetch(value)
end
