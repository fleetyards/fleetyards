# frozen_string_literal: true

# Components no build has ever described, that predate the game-file loads (no
# `sc_ref`), and that nothing points at. No catalogue lists a component without
# a build, so they were only weight on the columns the builds replaced.
#
# "Nothing points at" is read off the database at the moment this runs rather
# than from a list: every `component_id` column and every polymorphic pair that
# can name a Component, attachments included, so a reference added after this
# was written still keeps its component. A component's own history and the
# notifications about it describe the row rather than use it, so they do not.
class DeleteUnattachedLegacyComponents < ActiveRecord::Migration[8.1]
  DERIVED_TABLES = %w[component_builds component_build_changes].freeze

  DESCRIBING_PAIRS = [
    %w[versions item_type],
    %w[notifications record_type],
    %w[admin_notifications record_type]
  ].freeze

  def up
    unattached = Component
      .where(sc_ref: nil)
      .where.not(id: ComponentBuild.select(:component_id))

    references.each do |table, id_column, type_column|
      unattached = unattached.where("NOT EXISTS (#{referencing(table, id_column, type_column)})")
    end

    say "Deleted #{unattached.delete_all} unattached legacy components"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def referencing(table, id_column, type_column)
    column = connection.columns(table).find { |c| c.name == id_column }
    component_id = (column.type == :uuid) ? "components.id" : "components.id::text"

    sql = "SELECT 1 FROM #{connection.quote_table_name(table)} refs " \
      "WHERE refs.#{connection.quote_column_name(id_column)} = #{component_id}"
    sql += " AND refs.#{connection.quote_column_name(type_column)} = 'Component'" if type_column
    sql
  end

  private def references
    connection.tables.flat_map do |table|
      next [] if DERIVED_TABLES.include?(table)

      columns = connection.columns(table).index_by(&:name)
      direct = columns.key?("component_id") ? [[table, "component_id", nil]] : []
      polymorphic = columns.keys.grep(/_type\z/).filter_map do |type_column|
        next if DESCRIBING_PAIRS.include?([table, type_column])

        id_column = type_column.delete_suffix("_type") + "_id"
        [table, id_column, type_column] if %i[uuid string text].include?(columns[id_column]&.type)
      end

      direct + polymorphic
    end
  end
end
