# frozen_string_literal: true

module Inventories
  # Writes the ledger entries a transfer is made of.
  #
  # One class for all four source/destination combinations, including the two
  # that cross the user and fleet schemas. It never names either class: the
  # inventory it is handed exposes its ledger as `inventory_items` -- an alias
  # `InventoryStock` installs on both -- and says what a deposit into it needs
  # beyond the shared columns through `ledger_attributes_for`. That hook already
  # existed for the CSV importer, and it is exactly the difference between the
  # two tables: `fleet_inventory_items` is `inventory_items` plus `added_by` and
  # `member_id`.
  class TransferExecutor
    class Rejected < StandardError
      attr_reader :record

      def initialize(record)
        @record = record
        super(record.errors.full_messages.to_sentence)
      end
    end

    # `member_id` is deliberately never filled: a transfer from outside the
    # fleet cannot know which member the goods are for and must not guess. The
    # holder is not carried either -- goods arriving are carried by nobody until
    # someone takes them -- except back to the source, see `return_to_source`.
    CARRIED = %i[name category unit item_type item_id crafted_blueprint_id crafted_qualities].freeze

    def initialize(transfer, actor:)
      @transfer = transfer
      @actor = actor
    end

    # Stock leaves the source. This is what makes a pending transfer escrow
    # rather than a promise: the withdrawal is checked against live stock here
    # and now, so acceptance later can never fail for want of it.
    # One withdrawal per quality grade the line is spent across, so a
    # withdrawal never lands in a grade the stock does not hold -- see
    # `TransferLine`.
    def dispatch(lines, **holder)
      lines.flat_map do |line|
        line.allocations.map do |allocation|
          write(@transfer.source, line.attributes_for(allocation).merge(holder), :withdrawal)
        end
      end
    end

    # The far end of an accepted transfer.
    def deliver
      mirror_into(@transfer.destination)
    end

    # A refusal is a compensating deposit, not a deletion. The sender's history
    # reads -96, +96 rather than going quiet.
    #
    # Back into the share it left, so a refused shipment does not land in the
    # unassigned stock of a fleet that knew exactly who had it.
    def return_to_source
      mirror_into(@transfer.source, keep_holder: true)
    end

    private def mirror_into(inventory, keep_holder: false)
      raise ArgumentError, "no inventory to mirror into" if inventory.blank?

      @transfer.dispatched_entries.map do |entry|
        attributes = carried_from(entry)
        attributes[:holder_id] = entry.holder_id if keep_holder && entry.has_attribute?(:holder_id)

        write(inventory, attributes, :deposit)
      end
    end

    private def write(inventory, attributes, entry_type)
      entry = inventory.inventory_items.new(
        **attributes,
        entry_type:,
        inventory_transfer: @transfer,
        **inventory.ledger_attributes_for(@actor)
      )

      raise Rejected, entry unless entry.save

      entry
    end

    private def carried_from(entry)
      CARRIED.index_with { |column| entry.public_send(column) }
        .merge(quantity: entry.quantity, quality: entry.quality, notes: entry.notes)
    end
  end
end
