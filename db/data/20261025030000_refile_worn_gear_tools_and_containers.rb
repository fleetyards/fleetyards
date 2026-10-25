# frozen_string_literal: true

# Armour, clothing, tools and containers have categories of their own now, and
# the picker files a catalogue pick under them. A position recorded before that
# still sits under equipment (or, for the gadgets the game calls weapons, under
# weapon), so a withdrawal picked from the catalogue would land in a position
# holding nothing and be refused, and a contract asking for the piece would stop
# counting deposits. Each such position moves to its new category, merging into
# one already there; a contract item follows its catalogue record the same way.
#
# Only a position whose every entry names the same piece of equipment moves: a
# line typed by hand says nothing about what it is, and the category it was
# filed under is the only answer it has.
class RefileWornGearToolsAndContainers < ActiveRecord::Migration[8.1]
  # Its own copy on purpose: a migration has to keep running against the
  # mapping of its own moment.
  CATEGORIES_BY_EQUIPMENT_TYPE = {
    "armor" => "armor",
    "undersuit" => "armor",
    "clothing" => "clothing",
    "tool" => "tool",
    "mining_gadget" => "tool",
    "hacking_tool" => "tool",
    "container" => "container"
  }.freeze

  # The gadgets keep `weapon` as their type until the next game build is
  # parsed, so the parser's rule is read here as well.
  TOOL_SUB_TYPES = %w[Gadget].freeze
  TOOL_ITEM_TYPES = %w[medical_device medical_tool].freeze

  REFILED_FROM = %w[equipment weapon].freeze

  STOCKS = [
    [InventoryPosition, :inventory_items, :inventory_position_id, :inventory_id],
    [FleetInventoryPosition, :fleet_inventory_items, :fleet_inventory_position_id, :fleet_inventory_id]
  ].freeze

  def up
    STOCKS.each { |stock| refile_positions(*stock) }
    refile_contract_items
  end

  def down
  end

  private def refile_positions(position_class, entries, position_key, inventory_key)
    position_class.where(category: REFILED_FROM).find_each do |position|
      references = position.public_send(entries).distinct.pluck(:item_type, :item_id)

      next unless references.one? && references.first.first == "Equipment" && references.first.last.present?

      category = category_for(::Equipment.find_by(id: references.first.last))

      next if category.nil?

      position_class.transaction do
        destination = position_class.find_by(
          inventory_key => position.public_send(inventory_key),
          :name => position.name, :category => category, :unit => position.unit
        )

        if destination
          position.public_send(entries).update_all(position_key => destination.id)
          position.destroy!
          position = destination
        else
          position.update!(category:)
        end

        position.public_send(entries).update_all(
          category: ::InventoryLedgerEntry::CATEGORIES[category.to_sym], updated_at: Time.current
        )
      end
    end
  end

  private def refile_contract_items
    ::FleetContractItem.where(category: REFILED_FROM, item_type: "Equipment").find_each do |contract_item|
      category = category_for(::Equipment.find_by(id: contract_item.item_id))

      next if category.nil?

      taken = ::FleetContractItem.where(fleet_contract_id: contract_item.fleet_contract_id, category:, unit: contract_item.unit)
        .where("lower(name) = ?", contract_item.name.downcase).exists?

      contract_item.update_columns(category:, updated_at: Time.current) unless taken
    end
  end

  private def category_for(equipment)
    return if equipment.nil?

    tool = equipment.equipment_type == "weapon" &&
      (TOOL_SUB_TYPES.include?(equipment.sub_type) || TOOL_ITEM_TYPES.include?(equipment.item_type))

    tool ? "tool" : CATEGORIES_BY_EQUIPMENT_TYPE[equipment.equipment_type]
  end
end
