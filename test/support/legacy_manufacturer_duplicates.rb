# frozen_string_literal: true

# Lets a test build the duplicate manufacturers that predate
# index_manufacturers_on_slug.
#
# The dedupe task exists to clean up rows the database now refuses to hold, so
# its tests have to reproduce a table from before the index. Postgres DDL is
# transactional and each test runs in a transaction that is rolled back, so
# dropping the index here restores it when the test ends -- no teardown, and no
# other test sees it missing.
module LegacyManufacturerDuplicates
  def allow_duplicate_manufacturer_slugs
    return unless Manufacturer.connection.index_exists?(:manufacturers, :slug, unique: true)

    Manufacturer.connection.remove_index(:manufacturers, :slug)
  end
end
