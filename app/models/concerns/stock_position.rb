# frozen_string_literal: true

# The identity of a stock position: what makes two ledger entries the same
# position, held in a row of its own rather than derived from the labels on the
# entries.
#
# The unit-fits-category rule is deliberately *not* repeated here. A position
# has to be able to represent every entry that already exists, and entries
# predating that rule are grandfathered by it (`unit_fits_category` on the entry
# only fires when a unit or category is touched). Duplicating the check would
# give a legitimate backfill a way to fail. `InventoryStockItemChange` still
# enforces it where a user asks for a move.
#
# It carries only the identity. The quantities a position appears to have --
# `net_quantity`, the quality range, the entry count, the last entry -- are sums
# over the ledger and stay derived there. Storing them would let them drift from
# the entries they claim to describe, and the ledger is the record of truth.
module StockPosition
  extend ActiveSupport::Concern

  included do
    enum :category, ::InventoryLedgerEntry::CATEGORIES
    enum :unit, ::InventoryLedgerEntry::UNITS

    has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

    before_save :update_slugs

    validates :name, presence: true
  end

  class_methods do
    # Mirrors `InventoryLedgerEntry.inventory_association`: the inventory a
    # position belongs to is named differently on each side, and everything
    # below wants to reach it by one name.
    def inventory_association(association_name)
      belongs_to association_name

      if association_name != :inventory
        alias_method :inventory, association_name
        alias_attribute :inventory_id, :"#{association_name}_id"
      end

      @inventory_foreign_key = :"#{association_name}_id"
    end

    def inventory_foreign_key
      @inventory_foreign_key
    end
  end

  # The address, not the identity. Three published endpoints take
  # `name--category--unit` as a path segment, so it is stored rather than
  # recomputed on every render -- which also turns resolving one from a scan of
  # every position into a lookup.
  #
  # It is narrower than the identity it comes from: the name is parameterized,
  # so "Med Pens" and "med-pens" are two positions competing for one slug. The
  # suffix is what keeps the loser addressable instead of unreachable, which is
  # what it is today.
  private def update_slugs
    base = ::InventoryStockItem.slug_for(name:, category:, unit:)

    return if slug == base

    self.slug = base
    suffix = 1

    while self.class.where(self.class.inventory_foreign_key => inventory_id, :slug => slug).where.not(id:).exists?
      suffix += 1
      self.slug = "#{base}-#{suffix}"
    end
  end
end
