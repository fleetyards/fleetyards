# frozen_string_literal: true

# Each holder's share of a fleet inventory's stock, per lot and per position.
#
# One grouped query over the ledger and one for the holders' names, whatever
# the size of the stock list. A lot is keyed the way `current_stock` groups
# one, so a row of that list finds its own breakdown.
class InventoryHolderBalances
  Share = Struct.new(:holder, :net_quantity)

  LOT_COLUMNS = %i[fleet_inventory_position_id quality crafted_blueprint_id crafted_qualities].freeze

  def initialize(inventory, holder_id: :any)
    scope = inventory.fleet_inventory_items
    scope = scope.where(holder_id:) unless holder_id == :any

    @rows = scope
      .group(*LOT_COLUMNS, :holder_id)
      .having("#{InventoryStock::NET_QUANTITY} > 0")
      .pluck(*LOT_COLUMNS, :holder_id, Arel.sql(InventoryStock::NET_QUANTITY))

    @holders = User.where(id: @rows.filter_map { |row| row[4] }.uniq).index_by(&:id)
  end

  def for_lot(row)
    lot = [row.position_id, row.quality, row.crafted_blueprint_id, row.crafted_qualities]

    shares(@rows.select { |balance| balance.first(4) == lot })
  end

  def for_position(position_id)
    shares(@rows.select { |row| row.first == position_id })
  end

  # Largest share first, the unassigned share last: what a quartermaster
  # scans for is who to ask.
  private def shares(rows)
    rows
      .group_by { |row| row[4] }
      .map { |holder_id, held| Share.new(@holders[holder_id], held.sum { |row| row[5] }) }
      .sort_by { |share| [share.holder.nil? ? 1 : 0, -share.net_quantity] }
  end
end
