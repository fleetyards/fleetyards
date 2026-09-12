# frozen_string_literal: true

module Inventories
  # One position, and how much of it is moving.
  #
  # `quality` is the one thing a line cannot carry faithfully. A position rolls
  # up entries at several qualities -- `quality_min` and `quality_max` exist
  # because mined ore comes in grades -- and "32 of 96 SCU" cannot say which 32.
  # So it is copied when the position holds only one grade and left unset
  # otherwise: guessing a grade would be worse than not recording one, and null
  # is already the common case in the data.
  class TransferLine
    attr_reader :position, :stock_item, :quantity

    def initialize(position:, stock_item:, quantity:)
      @position = position
      @stock_item = stock_item
      @quantity = quantity
    end

    def attributes
      {
        name: position.name,
        category: position.category,
        unit: position.unit,
        quantity: quantity,
        quality: uniform_quality,
        item_type: reference&.item_type,
        item_id: reference&.item_id
      }
    end

    private def uniform_quality
      return unless stock_item.quality_min.present? && stock_item.quality_min == stock_item.quality_max

      stock_item.quality_min
    end

    # The entry the position borrows its catalogue link -- and therefore its
    # image -- from, so a commodity donated to a fleet arrives looking like that
    # commodity rather than as a bare hand-typed name.
    private def reference
      stock_item.reference_entry
    end
  end
end
