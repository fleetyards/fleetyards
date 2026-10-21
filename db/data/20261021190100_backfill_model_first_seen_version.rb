# frozen_string_literal: true

# Which live build first described a ship, for the ships we can still tell.
#
# Only the retained builds are left to read, so a ship already in the oldest of
# them stays blank: it arrived then or at any time before, and nothing here can
# say which. A ship whose first live build is a later one arrived with it.
class BackfillModelFirstSeenVersion < ActiveRecord::Migration[8.1]
  def up
    rows = select_rows(<<~SQL.squish)
      SELECT model_id, version FROM model_builds WHERE environment = 'live'
    SQL
    return if rows.empty?

    oldest = rows.map(&:last).uniq.min_by { |version| precedence(version) }

    rows.group_by(&:first).each do |model_id, builds|
      first = builds.map(&:last).min_by { |version| precedence(version) }
      next if first == oldest

      execute <<~SQL.squish
        UPDATE models SET first_seen_version = #{connection.quote(first)}
        WHERE id = #{connection.quote(model_id)} AND first_seen_version IS NULL
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # `ScData::Source#precedence` as of today: release, then build id.
  private def precedence(version)
    release, build = version.to_s.split("-", 2)

    [Gem::Version.correct?(release) ? Gem::Version.new(release) : Gem::Version.new(0), build.to_s[/\d+\z/].to_i]
  end
end
