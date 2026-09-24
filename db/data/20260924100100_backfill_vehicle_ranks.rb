# frozen_string_literal: true

# Ranks every user's vehicles in the order the hangar shows them by default
# (`Vehicle::DEFAULT_SORTING_PARAMS`), so a custom order starts from what the
# owner already sees.
#
# The ranks are fixed-width base-36 strings spread evenly below "z000", which
# leaves a few hundred values between neighbours for the largest hangar (~6k
# vehicles) before lexorank has to grow a rank by a character. Nothing may start
# with "z": lexorank treats "z" as the upper bound and raises when asked for a
# rank after one that begins with it.
#
# A hangar that already has ranks is never reordered: its unranked vehicles are
# appended after the last rank instead. Those are the vehicles the old release
# creates while this runs, so running it again once the new release is up fills
# them in.
class BackfillVehicleRanks < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  WIDTH = 4
  SPACE = 35 * 36**(WIDTH - 1)
  USER_BATCH = 500
  DEFAULT_ORDER = "vehicles.flagship DESC, vehicles.name ASC, models.name ASC, " \
    "vehicles.created_at ASC, vehicles.id ASC"

  def up
    user_ids = select_values(<<~SQL.squish)
      SELECT user_id FROM vehicles
      WHERE user_id IS NOT NULL
      GROUP BY user_id
      HAVING bool_and(rank IS NULL)
    SQL

    user_ids.each_slice(USER_BATCH) do |batch|
      execute(update_sql(batch))
    end

    append_unranked
  end

  def down
  end

  # Under the same per-owner lock `Vehicle#setup_rank` takes, so a vehicle
  # created while this runs cannot pick the rank being appended.
  private def append_unranked
    user_ids = select_values(<<~SQL.squish)
      SELECT user_id FROM vehicles
      WHERE user_id IS NOT NULL
      GROUP BY user_id
      HAVING bool_or(rank IS NULL) AND bool_or(rank IS NOT NULL)
    SQL

    user_ids.each do |user_id|
      Vehicle.transaction do
        Vehicle.lexorank_ranking.with_lock_if_enabled(Vehicle.new(user_id: user_id), transaction: true) do
          append_unranked_for(user_id)
        end
      end
    end
  end

  private def append_unranked_for(user_id)
    last = Vehicle.where(user_id: user_id).maximum(:rank)

    select_values(<<~SQL.squish).each do |id|
      SELECT vehicles.id
      FROM vehicles
      LEFT JOIN models ON models.id = vehicles.model_id
      WHERE vehicles.user_id = #{connection.quote(user_id)} AND vehicles.rank IS NULL
      ORDER BY #{DEFAULT_ORDER}
    SQL
      last = Vehicle.lexorank_ranking.value_between(last, nil)
      Vehicle.where(id: id).update_all(rank: last)
    end
  end

  private def update_sql(user_ids)
    <<~SQL.squish
      WITH ordered AS (
        SELECT
          vehicles.id,
          (row_number() OVER w * #{SPACE} / (count(*) OVER (PARTITION BY vehicles.user_id) + 1)) AS position
        FROM vehicles
        LEFT JOIN models ON models.id = vehicles.model_id
        WHERE vehicles.user_id IN (#{user_ids.map { |id| connection.quote(id) }.join(",")})
        WINDOW w AS (
          PARTITION BY vehicles.user_id
          ORDER BY #{DEFAULT_ORDER}
        )
      )
      UPDATE vehicles
      SET rank = #{base36("ordered.position")}
      FROM ordered
      WHERE vehicles.id = ordered.id
    SQL
  end

  private def base36(expression)
    (WIDTH - 1).downto(0).map do |power|
      digit = "((#{expression} / #{36**power}) % 36)"
      "chr(#{digit}::int + CASE WHEN #{digit} < 10 THEN 48 ELSE 87 END)"
    end.join(" || ")
  end
end
