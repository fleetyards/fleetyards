class CollapseComponentVersions < ActiveRecord::Migration[8.1]
  # Components used to be keyed on (sc_key, version), so the table holds a row
  # per component per imported build. They are one component, so this keeps one
  # row of each and repoints everything that referenced the others at it.
  #
  # The passes follow the loader's own lookup order -- sc_key, then sc_ref for
  # the rows that have no key, then name for the rows that have neither -- so
  # what collapses here is what the loader would now treat as one component.
  # They are scoped not to overlap, so no row is considered twice.
  PASSES = [
    {column: "lower(sc_key)", scope: "sc_key IS NOT NULL"},
    {column: "sc_ref", scope: "sc_key IS NULL AND sc_ref IS NOT NULL"},
    {column: "name", scope: "sc_key IS NULL AND sc_ref IS NULL AND name IS NOT NULL"}
  ].freeze

  # Everything holding a component_id. item_prices points at one polymorphically
  # and is handled on its own.
  REFERENCES = {
    "hardpoints" => "component_id",
    "model_hardpoints" => "component_id",
    "model_hardpoint_loadouts" => "component_id",
    "vehicle_loadout_hardpoints" => "component_id"
  }.freeze

  def up
    PASSES.each { |pass| collapse(pass) }

    execute("DROP TABLE IF EXISTS component_survivors")

    # Nothing should be able to put the table back the way it was.
    add_index :components, :sc_key, unique: true
  end

  def down
    remove_index :components, :sc_key

    raise ActiveRecord::IrreversibleMigration,
      "the duplicate rows are gone; a fresh import rebuilds the current build"
  end

  private def collapse(pass)
    say_with_time("collapsing components that share the same #{pass[:column]}") do
      execute("DROP TABLE IF EXISTS component_survivors")

      # The survivor is the row from the build the game currently ships, and
      # failing that the most recently updated -- version strings sort by text,
      # where 4.10 would come before 4.9.
      #
      # COALESCE rather than a bare comparison: production carries components
      # with no version at all, and `NULL = 'x'` is NULL, which Postgres sorts
      # ahead of true under DESC. Those rows would have won.
      execute(<<~SQL)
        CREATE TEMPORARY TABLE component_survivors AS
        SELECT id,
               FIRST_VALUE(id) OVER (
                 PARTITION BY #{pass[:column]}
                 ORDER BY COALESCE(version = #{quote(current_version)}, FALSE) DESC,
                          version DESC NULLS LAST,
                          updated_at DESC NULLS LAST,
                          id
               ) AS survivor_id
        FROM components
        WHERE #{pass[:scope]}
      SQL

      execute("CREATE INDEX ON component_survivors (id)")

      REFERENCES.each do |table, column|
        execute(<<~SQL)
          UPDATE #{table}
          SET #{column} = survivors.survivor_id
          FROM component_survivors survivors
          WHERE #{table}.#{column} = survivors.id
            AND survivors.id <> survivors.survivor_id
        SQL
      end

      execute(<<~SQL)
        UPDATE item_prices
        SET item_id = survivors.survivor_id
        FROM component_survivors survivors
        WHERE item_prices.item_type = 'Component'
          AND item_prices.item_id = survivors.id
          AND survivors.id <> survivors.survivor_id
      SQL

      # A component owns its sub-hardpoints through a polymorphic parent, and
      # those carry a foreign key back to components, so they go before the row
      # they hang off can.
      #
      # Hardpoints nest -- a turret owns the guns fitted to it -- and raw SQL
      # gets none of the `dependent: :destroy` cascade that would normally take
      # them. Deleting only the top level would leave the children pointing at a
      # parent that no longer exists, so the whole subtree goes.
      execute(<<~SQL)
        WITH RECURSIVE doomed AS (
          SELECT id
          FROM hardpoints
          WHERE parent_type = 'Component'
            AND parent_id IN (SELECT id FROM component_survivors WHERE id <> survivor_id)

          UNION ALL

          SELECT child.id
          FROM hardpoints child
          JOIN doomed ON child.parent_type = 'Hardpoint' AND child.parent_id = doomed.id
        )
        DELETE FROM hardpoints WHERE id IN (SELECT id FROM doomed)
      SQL

      execute("DELETE FROM components WHERE id IN (SELECT id FROM component_survivors WHERE id <> survivor_id)")
    end
  end

  private def current_version
    Rails.configuration.sc_data[:version].to_s
  end

  private def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
