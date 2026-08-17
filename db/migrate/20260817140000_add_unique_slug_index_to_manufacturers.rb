class AddUniqueSlugIndexToManufacturers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Nothing stopped two manufacturers sharing a slug, and the export handed us
  # seventeen pairs that did -- four rows answered to `aegis-dynamics`. The slug
  # is what the public API and the filters identify a manufacturer by, so a
  # duplicate makes those lookups pick one arbitrarily.
  #
  # Built after Maintenance::DedupeManufacturersTask has collapsed them, which is
  # a deliberate run rather than part of a deploy. Checked first because a
  # `concurrently` build that hits a duplicate does not just fail -- it leaves an
  # INVALID index behind that has to be dropped by hand before the next attempt.
  def up
    duplicates = ActiveRecord::Base.connection.select_rows(<<~SQL.squish)
      SELECT slug, COUNT(*) FROM manufacturers
      WHERE slug IS NOT NULL
      GROUP BY slug HAVING COUNT(*) > 1
      ORDER BY slug
    SQL

    if duplicates.any?
      listed = duplicates.map { |slug, count| "#{slug} (#{count})" }.join(", ")

      raise <<~MESSAGE
        #{duplicates.size} slug(s) are still shared by more than one manufacturer:
          #{listed}

        Run the "Dedupe manufacturers" maintenance task in this environment first
        -- with dry_run on to review it, then again with dry_run off -- and
        migrate afterwards.
      MESSAGE
    end

    add_index :manufacturers, :slug, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :manufacturers, :slug, algorithm: :concurrently, if_exists: true
  end
end
