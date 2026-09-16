# frozen_string_literal: true

# The two tables the hangar's bulk deletions used to strand.
#
# Both are `dependent: :destroy` on `Vehicle` and both `belongs_to :vehicle`
# without `optional`, so a row naming no vehicle was never a state either model
# could express -- but nothing at the database level said so, and the
# hand-maintained delete list in `Vehicle.delete_with_dependents` was free to
# miss them. `vehicle_loadouts` is the one that had a constraint, which is why
# that table turned a silent orphan into an `ActiveRecord::InvalidForeignKey`
# and surfaced the other two. See #4946.
#
# `ON DELETE CASCADE` rather than `:nullify`: the column is not nullable in any
# sense the models recognise, so nullifying would trade a dangling reference for
# a row that fails its own validations. Cascade is what `dependent: :destroy`
# already means, and it makes a future `delete_all` that forgets these tables
# correct instead of silent.
#
# `NOT NULL` alongside it, for the same reason and against a real path:
# `HangarSync#file_into_group` fills `task_forces` with `insert_all`, which sees
# no validations at all. Neither column holds a null today -- 0 of 1,063,946 and
# 0 of 96,229 -- so the two constraints together say what the models already
# assume. `SET NOT NULL` scans the table under an exclusive lock, which on
# `fleet_vehicles` is the largest of the two and still well under a second.
#
# `Maintenance::DropVehicleOrphansTask` (#4871) cleared the 195,457 and 18,278
# rows that were already there, so the count below is a guard rather than a
# step. It refuses instead of deleting: those rows are a decision that task
# owns, and `data:migrate` runs unattended inside the Kamal pre-deploy hook.
class AddVehicleForeignKeysToJoinTables < ActiveRecord::Migration[8.1]
  TABLES = [:fleet_vehicles, :task_forces]

  def up
    TABLES.each do |table|
      # `v.id IS NULL` on a left join covers both halves of what follows: a row
      # naming a vehicle that is gone, and a row naming none at all. Either one
      # blocks the constraints below, so either one has to be counted.
      ownerless = select_value(<<~SQL).to_i
        SELECT COUNT(*) FROM #{table} t
        LEFT JOIN vehicles v ON v.id = t.vehicle_id
        WHERE v.id IS NULL
      SQL

      if ownerless.positive?
        raise ActiveRecord::MigrationError,
          "#{ownerless} row(s) in #{table} name no vehicle, or one that no longer exists. " \
          "Run Maintenance::DropVehicleOrphansTask with dry_run => \"0\" first."
      end

      change_column_null table, :vehicle_id, false
      add_foreign_key table, :vehicles, column: :vehicle_id, on_delete: :cascade
    end
  end

  def down
    TABLES.each do |table|
      remove_foreign_key table, :vehicles, column: :vehicle_id
      change_column_null table, :vehicle_id, true
    end
  end
end
