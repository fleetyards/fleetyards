# frozen_string_literal: true

class AddPaintIndexToVehicles < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_vehicles_on_model_paint_id_where_painted"

  # The paint stats read the whole 1.57M-row table to reach the 51k vehicles
  # that carry a paint. Partial, so the index holds only those; the three
  # booleans ride along so the grouped count answers from the index without
  # touching the heap, and `model_paint_id` leads so it comes out grouped.
  def up
    drop_invalid_index

    add_index :vehicles, [:model_paint_id, :hidden, :wanted, :loaner],
      where: "model_paint_id IS NOT NULL",
      name: INDEX_NAME,
      algorithm: :concurrently,
      if_not_exists: true
  end

  def down
    remove_index :vehicles, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
  end

  # A `concurrently` build that is interrupted leaves an INVALID index behind,
  # which `if_not_exists` would then take for a finished one. Clearing it keeps
  # a failed deploy a re-run rather than a hand repair.
  private def drop_invalid_index
    leftover = ActiveRecord::Base.connection.select_value(<<~SQL.squish)
      SELECT pg_class.relname FROM pg_index
      JOIN pg_class ON pg_class.oid = pg_index.indexrelid
      WHERE pg_index.indrelid = 'vehicles'::regclass
        AND pg_class.relname = '#{INDEX_NAME}'
        AND NOT pg_index.indisvalid
    SQL

    return if leftover.blank?

    say "Dropping #{leftover}, left INVALID by an earlier attempt"

    remove_index :vehicles, name: INDEX_NAME, algorithm: :concurrently
  end
end
