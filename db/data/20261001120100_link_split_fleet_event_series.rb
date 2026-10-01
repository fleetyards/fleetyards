# frozen_string_literal: true

# Series split before `split_from_id` existed carry nothing that says which
# event they continue. A split leaves its marks, though: the original, in the
# same fleet, with the same title and the same rhythm, ends the day before the
# successor's first occurrence -- a date in the event's own zone -- and was
# there first. A successor is linked only when exactly one event fits;
# anything less certain stays unlinked, which reads as two events.
class LinkSplitFleetEventSeries < ActiveRecord::Migration[8.1]
  def up
    # `starts_at` holds UTC without a zone, so it is read as UTC before it is
    # turned into the event's local date.
    execute <<~SQL.squish
      WITH successors AS (
        SELECT successor.*,
          ((successor.starts_at AT TIME ZONE 'UTC') AT TIME ZONE COALESCE(zones.name, 'UTC'))::date AS first_day
        FROM fleet_events successor
        LEFT JOIN pg_timezone_names zones ON zones.name = successor.timezone
        WHERE successor.recurring AND successor.split_from_id IS NULL
      ),
      candidates AS (
        SELECT successors.id AS successor_id, min(original.id::text)::uuid AS original_id
        FROM successors
        JOIN fleet_events original
          ON original.fleet_id = successors.fleet_id
          AND lower(original.title) = lower(successors.title)
          AND original.id <> successors.id
          AND original.recurring
          AND original.created_at < successors.created_at
          AND original.recurrence_interval IS NOT DISTINCT FROM successors.recurrence_interval
          AND original.recurrence_every = successors.recurrence_every
          AND original.timezone = successors.timezone
          AND original.recurrence_until = successors.first_day - 1
        GROUP BY successors.id
        HAVING count(*) = 1
      )
      UPDATE fleet_events
      SET split_from_id = candidates.original_id
      FROM candidates
      WHERE fleet_events.id = candidates.successor_id
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
