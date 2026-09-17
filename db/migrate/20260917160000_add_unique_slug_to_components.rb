class AddUniqueSlugToComponents < ActiveRecord::Migration[8.1]
  # A component's name is not unique and never was: 112 ships each mount a
  # "Manned Turret", 313 carry an "Internal Tank". `slug` had no index at all,
  # so nothing ever stopped them sharing one. A public detail page needs a key
  # that resolves to exactly one row, which means backfilling before the index
  # can go on.
  #
  # The suffix comes from `sc_key` rather than a counter: it is unique, it is
  # stable across a patch, and a positional suffix would silently renumber a
  # live URL the first time the game shipped one more of something.
  def up
    say_with_time "backfilling unique component slugs" do
      backfill
    end

    add_index :components, :slug, unique: true
  end

  def down
    remove_index :components, :slug
  end

  private def backfill
    rows = select_all(<<~SQL).to_a
      SELECT id, name, sc_key FROM components WHERE name IS NOT NULL AND name <> ''
    SQL

    # A base shared by more than one row gives every one of its members a
    # suffix, rather than handing the bare slug to whichever happened to load
    # first -- that choice would differ between a restored dump and production.
    shared = rows.group_by { |row| base_slug(row["name"]) }
      .select { |_, group| group.size > 1 }
      .keys.to_set

    taken = Set.new
    updates = rows.filter_map do |row|
      base = base_slug(row["name"])
      next if base.blank?

      slug = shared.include?(base) ? disambiguate(base, row) : base

      # Two different names can still parameterize onto one slug.
      suffix = 1
      while taken.include?(slug)
        suffix += 1
        slug = "#{base}-#{suffix}"
      end
      taken << slug

      [row["id"], slug]
    end

    updates.each_slice(500) do |slice|
      values = slice.map { |id, slug| "(#{quote(id)}::uuid, #{quote(slug)})" }.join(", ")
      execute(<<~SQL)
        UPDATE components SET slug = v.slug
        FROM (VALUES #{values}) AS v(id, slug)
        WHERE components.id = v.id
      SQL
    end

    execute("UPDATE components SET slug = NULL WHERE name IS NULL OR name = ''")
  end

  private def base_slug(name)
    name.to_s.parameterize.presence
  end

  private def disambiguate(base, row)
    key = row["sc_key"].to_s.tr("_", "-").parameterize.presence

    key ? "#{base}-#{key}" : base
  end
end
