# frozen_string_literal: true

class SwapVehicleHangarFilterIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_vehicles_on_hidden_and_loaner_and_wanted"
  SUPERSEDED_INDEX_NAME = "index_vehicles_on_hidden_and_loaner"

  # The hangar counts filter on all three flags, and every one of them read
  # the 197MB table because `wanted` was missing from the index. Three
  # booleans deduplicate down to the 10MB the old index already took.
  #
  # `wanted` goes last so the columns the old index held stay a prefix of this
  # one: a count of everything hidden and unloaned still reads a contiguous
  # range rather than filtering `loaner` across the whole `hidden` side of the
  # index, which the planner costs at two thirds.
  #
  # Built before the old one goes, so no window is left without an index.
  def up
    drop_invalid_index(INDEX_NAME)

    add_index :vehicles, [:hidden, :loaner, :wanted],
      name: INDEX_NAME, algorithm: :concurrently, if_not_exists: true
    remove_index :vehicles, name: SUPERSEDED_INDEX_NAME,
      algorithm: :concurrently, if_exists: true
  end

  def down
    drop_invalid_index(SUPERSEDED_INDEX_NAME)

    add_index :vehicles, [:hidden, :loaner],
      name: SUPERSEDED_INDEX_NAME, algorithm: :concurrently, if_not_exists: true
    remove_index :vehicles, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
  end

  # A `concurrently` build that is interrupted leaves an INVALID index behind,
  # which `if_not_exists` would then take for a finished one -- and the drop
  # that follows would leave the table with nothing usable. Both directions
  # build an index, so both have to clear the one they are about to build.
  private def drop_invalid_index(name)
    leftover = ActiveRecord::Base.connection.select_value(<<~SQL.squish)
      SELECT pg_class.relname FROM pg_index
      JOIN pg_class ON pg_class.oid = pg_index.indexrelid
      WHERE pg_index.indrelid = 'vehicles'::regclass
        AND pg_class.relname = '#{name}'
        AND NOT pg_index.indisvalid
    SQL

    return if leftover.blank?

    say "Dropping #{leftover}, left INVALID by an earlier attempt"

    remove_index :vehicles, name: name, algorithm: :concurrently
  end
end
