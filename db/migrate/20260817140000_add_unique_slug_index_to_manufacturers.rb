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
  # INVALID index behind, and a second attempt would collide with that leftover
  # rather than report the duplicate that caused it.
  #
  # The check cannot make the build safe on its own: the importers write while
  # the migration runs, so a manufacturer whose name slugs onto an existing one
  # can still arrive between the two statements. That is what clearing the
  # leftover is for -- the failure stays a re-run rather than a hand repair.
  def up
    drop_invalid_index

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

  private

  def drop_invalid_index
    leftover = ActiveRecord::Base.connection.select_value(<<~SQL.squish)
      SELECT pg_class.relname FROM pg_index
      JOIN pg_class ON pg_class.oid = pg_index.indexrelid
      WHERE pg_index.indrelid = 'manufacturers'::regclass
        AND pg_class.relname = 'index_manufacturers_on_slug'
        AND NOT pg_index.indisvalid
    SQL

    return if leftover.blank?

    say "Dropping #{leftover}, left INVALID by an earlier attempt"

    remove_index :manufacturers, :slug, algorithm: :concurrently
  end
end
