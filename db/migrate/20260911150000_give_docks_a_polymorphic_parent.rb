# frozen_string_literal: true

# A dock belongs to something, and until now that something could only be a
# model -- or nothing at all, since `model_id` was nullable. Both halves were
# wrong. The Galaxy's medic module carries a vehicle lift, and the Caterpillar
# may get one, so a dock hangs off a `ModelModule` just as readily as off a
# ship. `cargo_holds` already works this way and is the shape copied here.
#
# Nullable was never a state that meant anything: #4864 deleted the 391 rows
# that had drifted into it, all of them left over from a 2021 station script.
#
# `model_id` stays behind for one release. The running containers are migrated
# before the new ones boot, so a column the old code still selects cannot be
# dropped in the same deploy without 500ing every dock read in between.
#
# Reads are what that protects. Writes are not: for the length of the pre-deploy
# window the old code still creates docks with `model_id` alone, and the NOT NULL
# below rejects those. The alternative is two releases -- nullable here, enforced
# later -- and the trade was made knowingly: the catalogue holds 28 docks in
# total, creating one is a rare admin action, and the failure is a retryable
# error on that one request rather than anything the data carries afterwards.
class GiveDocksAPolymorphicParent < ActiveRecord::Migration[8.1]
  def up
    add_column :docks, :parent_type, :string
    add_column :docks, :parent_id, :uuid

    execute(<<~SQL)
      UPDATE docks
      SET parent_type = 'Model', parent_id = model_id
      WHERE model_id IS NOT NULL
    SQL

    # #4864 cleared these, so this is a guard rather than a step: a dock with no
    # parent cannot be expressed once the columns are NOT NULL, and silently
    # keeping one is not an option the schema leaves open.
    orphans = select_value("SELECT COUNT(*) FROM docks WHERE parent_id IS NULL").to_i
    if orphans.positive?
      say("deleting #{orphans} dock(s) that belong to nothing")
      execute("DELETE FROM docks WHERE parent_id IS NULL")
    end

    change_column_null :docks, :parent_type, false
    change_column_null :docks, :parent_id, false

    add_index :docks, [:parent_type, :parent_id]
  end

  def down
    remove_index :docks, [:parent_type, :parent_id]

    # `model_id` cannot express a dock on a module, so rolling back would have to
    # throw those rows away. A rollback is usually run to get out of an
    # unrelated problem, and losing curation nobody was thinking about is not an
    # acceptable side effect of that -- so it refuses instead.
    orphaned = select_value("SELECT COUNT(*) FROM docks WHERE parent_type <> 'Model'").to_i
    if orphaned.positive?
      raise ActiveRecord::IrreversibleMigration,
        "#{orphaned} dock(s) hang off something other than a Model and cannot be " \
        "expressed by model_id. Move or delete them first if this really has to roll back."
    end

    execute("UPDATE docks SET model_id = parent_id WHERE parent_type = 'Model'")

    remove_column :docks, :parent_id
    remove_column :docks, :parent_type
  end
end
