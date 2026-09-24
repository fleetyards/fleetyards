# frozen_string_literal: true

module Contracts
  # Where a contract's goods may be sent, as seen by whoever is writing it.
  #
  # Two independent halves. The fleet inventories are the ones the editor could
  # accept a delivery into -- the same question `TransferAuthorizer` asks of a
  # transfer, so an officers-only store is not offered to a plain member. The
  # hangar inventories are the author's own, because a delivery into one is
  # addressed to the author and only they can answer it.
  #
  # An author with fleet rights gets both lists: nothing about either half
  # depends on the other.
  class DestinationOptions
    def initialize(fleet:, editor:, author: editor)
      @fleet = fleet
      @editor = editor
      @author = author
      @authorizer = ::Inventories::TransferAuthorizer.new(editor)
    end

    # Only while the fleet's logistics are on: the transfer endpoint refuses
    # every delivery into a fleet inventory otherwise.
    def fleet_inventories
      return [] if @editor.blank?
      return [] unless Flipper.enabled?(:fleet_logistics, @editor, @fleet)

      @fleet_inventories ||= @fleet.fleet_inventories.order(:name).to_a
        .select { |inventory| @authorizer.may_deposit_into?(inventory) }
    end

    # Only while the author can actually receive a transfer. Offering an
    # inventory nobody can deliver into would post a contract that can never
    # be worked. Each kind has its own flag, the same one the transfer
    # endpoints check: a ship's hold takes the ship flag, anything else the
    # hangar one.
    def hangar_inventories
      return [] unless author_can_receive?

      @hangar_inventories ||= @author.inventories.order(:name).to_a
        .select { |inventory| Flipper.enabled?(inventory_flag(inventory), @author) }
    end

    def allows?(destination)
      case destination
      when ::FleetInventory then fleet_inventories.include?(destination)
      when ::Inventory then hangar_inventories.include?(destination)
      else false
      end
    end

    private def author_can_receive?
      return false if @author.blank? || @author != @editor

      Flipper.enabled?(:inventory_transfers, @author)
    end

    private def inventory_flag(inventory)
      inventory.vehicle? ? :ship_inventories : :hangar_inventories
    end
  end
end
