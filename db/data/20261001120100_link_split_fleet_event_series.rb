# frozen_string_literal: true

# Series split before `split_from_id` existed carry nothing that says which
# event they continue. A split leaves its marks, though: the original, in the
# same fleet and with the same title, ends the day before the successor's first
# occurrence, and was there first. A successor is linked only when exactly one
# event fits; anything less certain stays unlinked, which reads as two events.
class LinkSplitFleetEventSeries < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE fleet_events successor
      SET split_from_id = candidates.original_id
      FROM (
        SELECT successor.id AS successor_id, min(original.id::text)::uuid AS original_id
        FROM fleet_events successor
        JOIN fleet_events original
          ON original.fleet_id = successor.fleet_id
          AND lower(original.title) = lower(successor.title)
          AND original.id <> successor.id
          AND original.recurring
          AND original.created_at < successor.created_at
          AND original.recurrence_until = (successor.starts_at AT TIME ZONE COALESCE((SELECT name FROM pg_timezone_names WHERE name = successor.timezone), 'UTC'))::date - 1
        WHERE successor.recurring AND successor.split_from_id IS NULL
        GROUP BY successor.id
        HAVING count(*) = 1
      ) candidates
      WHERE successor.id = candidates.successor_id
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
