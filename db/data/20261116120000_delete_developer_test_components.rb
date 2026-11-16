# frozen_string_literal: true

# The developer stand-ins the items load now leaves out (`mine_test`,
# `mining_laser_test_best`, `behr_lasercannon_s7_idris_m_dummy`, ...). They
# borrow a real item's name, so the catalogue listed a second "Argos IX
# Torpedo" that no one can fit.
#
# What the game files wrote about them goes with them: their builds, prices,
# own ports, and the AI ships' slots that loaded one. A component a player's
# data points at -- an inventory, a loadout, a pledge -- is kept, retired by the
# next load instead. That is read off the schema, as in
# DeleteUnattachedLegacyComponents, so a reference added later still counts.
class DeleteDeveloperTestComponents < ActiveRecord::Migration[8.1]
  KEY_PATTERN = "(^|_)(test|dummy)(_|$)"

  # Written by the game files or the price sync, and cleared below or by
  # `destroy`, so a row there does not keep a stand-in. Attachments are
  # checked apart from these: the icon is the load's, the store image curated.
  GAME_DATA_TABLES = %w[
    component_builds component_build_changes hardpoints hardpoint_builds
    item_prices item_price_snapshots model_paints
  ].freeze

  DESCRIBING_PAIRS = [
    %w[versions item_type],
    %w[notifications record_type],
    %w[admin_notifications record_type]
  ].freeze

  def up
    stand_ins = Component.where("components.sc_key ~* ?", KEY_PATTERN)

    references.each do |table, id_column, type_column|
      stand_ins = stand_ins.where("NOT EXISTS (#{referencing(table, id_column, type_column)})")
    end

    ids = stand_ins.pluck(:id)

    slot_ids = Hardpoint.where(component_id: ids).pluck(:id)
    HardpointBuild.where(component_id: ids).update_all(component_id: nil)
    ItemPriceSnapshot.where(item_type: "Component", item_id: ids).delete_all
    Component.where(id: ids).find_each(&:destroy!)

    # `destroy` empties the slots without a touch. Touching each one walks up
    # through a turret's ports to the hull, whose cached payload embeds them.
    Hardpoint.where(id: slot_ids).find_each(&:touch)

    say "Deleted #{ids.size} developer test components"
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
    sql += " AND refs.name <> 'icon'" if table == "active_storage_attachments"
    sql
  end

  private def references
    connection.tables.flat_map do |table|
      next [] if GAME_DATA_TABLES.include?(table)

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
