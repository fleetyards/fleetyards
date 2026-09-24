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
# Users with any ranked vehicle are skipped, so a re-run never reorders a hangar
# and never collides with the unique index.
class BackfillVehicleRanks < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  WIDTH = 4
  SPACE = 35 * 36**(WIDTH - 1)
  USER_BATCH = 500

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
  end

  def down
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
          ORDER BY vehicles.flagship DESC, vehicles.name ASC, models.name ASC,
            vehicles.created_at ASC, vehicles.id ASC
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
