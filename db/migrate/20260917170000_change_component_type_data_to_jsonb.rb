class ChangeComponentTypeDataToJsonb < ActiveRecord::Migration[8.1]
  # `type_data` held every metric a component has, as a YAML string. No SQL
  # reached inside it, so nothing could filter, sort or index on a single
  # figure -- which is why `ComponentBuild::FILTERABLE` leaves every serialised
  # column out. A catalogue that cannot answer "shields by max health" stops
  # there. As jsonb the whole structure becomes queryable at once, instead of
  # one migration per metric promoted to its own column.
  #
  # DEPLOY WINDOW: pre-deploy migrates before the new release boots, so between
  # the two the old code reads a jsonb column through its YAML coder. Deploy
  # this one deliberately rather than alongside a busy release.
  #
  # Unlike 20260811130000, which dropped and re-added and waited for a loader
  # run, this converts the rows it finds -- `component_builds` keeps a row per
  # build, and an older build's metrics are not reloadable.
  PERMITTED = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess].freeze

  TABLES = %i[components component_builds].freeze

  def up
    TABLES.each do |table|
      add_column table, :type_data_jsonb, :jsonb

      say_with_time "converting #{table}.type_data to jsonb" do
        convert(table)
      end

      remove_column table, :type_data
      rename_column table, :type_data_jsonb, :type_data
    end
  end

  def down
    TABLES.each do |table|
      add_column table, :type_data_yaml, :string

      say_with_time "converting #{table}.type_data back to YAML" do
        revert_rows(table)
      end

      remove_column table, :type_data
      rename_column table, :type_data_yaml, :type_data
    end
  end

  private def convert(table)
    each_batch(table, :type_data) do |rows|
      write_batch(table, :type_data_jsonb, rows) { |value| to_json(value) }
    end
  end

  private def revert_rows(table)
    each_batch(table, :type_data) do |rows|
      write_batch(table, :type_data_yaml, rows) { |value| JSON.parse(value).with_indifferent_access.to_yaml }
    end
  end

  # Two formats sit in this column, not one. Every one of the 5,538 component
  # rows and 9,072 of the build rows hold the YAML the serializer wrote. The
  # other 4,556 -- all of them in `4.9.0-live.12344265`, the backfilled build --
  # hold a Ruby `Hash#inspect` string, written by something that handed the hash
  # straight to a string column. Those have never parsed as YAML, so they have
  # been unreadable since they landed.
  #
  # Anything matching neither raises rather than converting to NULL: losing a
  # component's metrics quietly is worse than a migration that stops.
  private def to_json(value)
    parsed =
      case value
      when /\A---/ then YAML.safe_load(value, permitted_classes: PERMITTED, aliases: true)
      when /\A\{/ then JSON.parse(value.gsub(" => ", ": ").gsub(/:\s*nil\b/, ": null"))
      else raise "unrecognised type_data: #{value[0, 80].inspect}"
      end

    parsed&.to_json
  end

  # Keyset paging on id rather than OFFSET: the column being read is the one
  # every row carries, and 21,861 rows of YAML is more than one result set
  # wants to hold.
  private def each_batch(table, column)
    last = nil

    loop do
      scope = last ? "AND id > #{quote(last)}::uuid" : ""
      rows = select_all(<<~SQL).to_a
        SELECT id, #{column} AS value FROM #{table}
        WHERE #{column} IS NOT NULL #{scope}
        ORDER BY id LIMIT 500
      SQL
      break if rows.empty?

      yield rows
      last = rows.last["id"]
    end
  end

  private def write_batch(table, column, rows)
    values = rows.filter_map do |row|
      converted = yield(row["value"])
      next if converted.nil?

      "(#{quote(row["id"])}::uuid, #{quote(converted)})"
    end
    return if values.empty?

    execute(<<~SQL)
      UPDATE #{table} SET #{column} = v.value#{"::jsonb" if column == :type_data_jsonb}
      FROM (VALUES #{values.join(", ")}) AS v(id, value)
      WHERE #{table}.id = v.id
    SQL
  end
end
