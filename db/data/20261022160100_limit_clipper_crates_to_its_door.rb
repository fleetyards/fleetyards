# frozen_string_literal: true

# The Clipper's grid fits an 8 SCU crate, but its door takes nothing above
# 2 SCU, and the game files describe no door. Left alone where an admin has
# already set a limit.
class LimitClipperCratesToItsDoor < ActiveRecord::Migration[8.1]
  SIZE = 2

  def up
    hold_ids = select_values(<<~SQL.squish)
      UPDATE cargo_holds
      SET max_loadable_container_size_scu = #{SIZE}, updated_at = NOW()
      FROM models
      WHERE cargo_holds.parent_type = 'Model'
        AND cargo_holds.parent_id = models.id
        AND models.slug = 'drak-clipper'
        AND cargo_holds.max_loadable_container_size_scu IS NULL
        AND cargo_holds.max_container_size_scu > #{SIZE}
      RETURNING cargo_holds.id
    SQL

    return if hold_ids.empty?

    ids = hold_ids.map { |id| connection.quote(id) }.join(", ")

    execute <<~SQL.squish
      UPDATE cargo_hold_container_capacities
      SET max_quantity = 0, best_orientation = NULL, updated_at = NOW()
      WHERE cargo_hold_id IN (#{ids}) AND container_size_scu > #{SIZE}
    SQL

    execute "UPDATE models SET updated_at = NOW() WHERE slug = 'drak-clipper'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
