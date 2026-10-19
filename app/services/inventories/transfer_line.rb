# frozen_string_literal: true

module Inventories
  # One position, how much of it is moving, and which quality grades that comes
  # out of.
  #
  # A position holds entries at several grades -- mined ore comes that way -- so
  # "5 of 105 SCU" has to say *which* 5. Taking the amount and leaving the grade
  # unset, which is what this did first, writes a withdrawal into a quality
  # group no deposit occupies. `current_stock` groups by quality and hides any
  # group that is not positive, so those withdrawals became invisible: the list
  # kept showing the original 105 while the position's real net fell to 60, and
  # the same 5 SCU could be sent again and again against a number that never
  # moved.
  #
  # So a line is spent across the grades that are actually there, one withdrawal
  # per grade, and the deposits mirror them -- which keeps the grades rather
  # than losing them.
  #
  # A crafted part is a lot of its own in the same way, and travels with the
  # recipe and grades it was made from.
  class TransferLine
    Lot = Struct.new(:quality, :crafted_blueprint_id, :crafted_qualities) do
      def crafted?
        crafted_blueprint_id.present?
      end
    end

    Allocation = Struct.new(:lot, :quantity) do
      delegate :quality, to: :lot
    end

    attr_reader :position, :stock_item, :quantity, :grades

    # `grades` is [[lot, available], ...], where a lot may also be a bare
    # quality. Lowest first, and nil -- stock nobody graded -- ahead of
    # everything, and crafted parts after all of it: a transfer ships what is
    # least valuable unless it is shipping the lot.
    def initialize(position:, stock_item:, quantity:, grades: [])
      @position = position
      @stock_item = stock_item
      @quantity = quantity
      @grades = grades
        .map { |lot, amount| [lot.is_a?(Lot) ? lot : Lot.new(lot), amount] }
        .sort_by { |lot, _| [lot.crafted? ? 1 : 0, lot.quality.nil? ? 0 : 1, lot.quality.to_i] }
    end

    def available
      grades.sum { |_, amount| amount.to_d }
    end

    # `each_with_object` rather than `filter_map`, because a `break` inside
    # `filter_map` returns nil for the whole call rather than the entries
    # gathered so far.
    def allocations
      remaining = quantity.to_d

      grades.each_with_object([]) do |(lot, amount), taken|
        next if remaining <= 0

        amount = [remaining, amount.to_d].min
        next if amount <= 0

        remaining -= amount

        taken << Allocation.new(lot, amount)
      end
    end

    def attributes_for(allocation)
      {
        name: position.name,
        category: position.category,
        unit: position.unit,
        quantity: allocation.quantity,
        quality: allocation.quality,
        item_type: reference&.item_type,
        item_id: reference&.item_id,
        crafted_blueprint_id: allocation.lot.crafted_blueprint_id,
        crafted_qualities: allocation.lot.crafted_qualities
      }
    end

    # The entry the position borrows its catalogue link -- and therefore its
    # image -- from, so a commodity donated to a fleet arrives looking like that
    # commodity rather than as a bare hand-typed name.
    private def reference
      stock_item.reference_entry
    end
  end
end
