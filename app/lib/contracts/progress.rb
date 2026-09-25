# frozen_string_literal: true

module Contracts
  # How far a contract has actually got, read out of the transfer ledger.
  #
  # Nothing is stored. Delivered quantity is a sum over the deposits that
  # transfers naming this contract wrote into where they were delivered, and
  # those deposits only exist once a transfer was accepted -- a declined,
  # cancelled or expired one compensates back into its *source*, so
  # it contributes nothing here without any state having to be consulted.
  #
  # Where a delivery landed matters only for a transfer made straight into an
  # inventory: that one counts when it is the contract's destination. A
  # transfer addressed to whoever answers for the destination counts wherever
  # they accepted it, because the inventory was theirs to choose. A pickup is
  # addressed to its courier, so it never counts as delivered.
  #
  # Two queries, not two per line: the entries are aggregated in the database
  # down to one row per (position, quality, transfer) and bucketed into lines in
  # Ruby, because the quality threshold differs per line and a per-line query
  # would be N round trips to apply it.
  class Progress
    # What a contractor delivered against one line, and what it is worth when
    # the reward is divided.
    Contribution = Struct.new(:user_id, :delivered, :weight)

    LineProgress = Struct.new(
      :item, :requested, :delivered, :picked_up, :contributions
    ) do
      def remaining
        [requested - delivered, 0.to_d].max
      end

      def complete?
        delivered >= requested
      end

      # Capped at 1: over-delivering on a line does not make it worth more than
      # it asked for.
      def fraction
        return 0.to_d if requested.zero?

        [delivered / requested, 1.to_d].min
      end
    end

    # What a board shows for one contract: a bar, and the quantities behind it
    # when every line is measured the same way.
    Summary = Struct.new(:fraction, :delivered, :requested, :unit, :complete)

    # One page of contracts, in a bounded number of queries rather than three
    # per row: the ledger is rolled up once for every transfer on the page and
    # handed to each contract pre-sliced.
    def self.for_all(contracts)
      contracts = contracts.to_a
      return {} if contracts.empty?

      transfers = ::InventoryTransfer
        .where(fleet_contract_id: contracts.map(&:id))
        .includes(source_inventory: {}, source_fleet_inventory: {})
        .group_by(&:fleet_contract_id)

      all_transfers = transfers.values.flatten
      transfer_ids = all_transfers.map(&:id)
      fleet_inventory_ids = (contracts.flat_map do |contract|
        [contract.destination_fleet_inventory_id, contract.source_fleet_inventory_id]
      end + all_transfers.map(&:destination_fleet_inventory_id)).compact.uniq
      hangar_inventory_ids = (contracts.map(&:destination_inventory_id) +
        all_transfers.map(&:destination_inventory_id)).compact.uniq

      # Keyed by inventory id, and the two ledgers' ids never collide, so the
      # halves merge into one lookup.
      deposits = batch_rollup(::FleetInventoryItem, fleet_inventory_ids, transfer_ids, :deposit)
        .merge(batch_rollup(::InventoryItem, hangar_inventory_ids, transfer_ids, :deposit))
      withdrawals = batch_rollup(::FleetInventoryItem, fleet_inventory_ids, transfer_ids, :withdrawal)

      contracts.index_by(&:id).transform_values do |contract|
        own_transfers = transfers.fetch(contract.id, [])

        new(
          contract,
          preloaded: {
            transfers: own_transfers,
            deposits: deposits,
            withdrawals: withdrawals
          }
        )
      end
    end

    # The same shape `rollup` returns, for every inventory at once: keyed by
    # inventory so a contract can take only the rows written into its own ends.
    private_class_method def self.batch_rollup(ledger, inventory_ids, transfer_ids, entry_type)
      return {} if inventory_ids.empty? || transfer_ids.empty?

      column = ledger_column(ledger)
      rows = ledger
        .where(column => inventory_ids, :entry_type => entry_type)
        .where(inventory_transfer_id: transfer_ids)
        .group(column, Arel.sql("LOWER(name)"), :category, :unit, :quality,
          :inventory_transfer_id)
        .sum(:quantity)

      rows.each_with_object({}) do |(key, quantity), result|
        inventory_id, name, category, unit, quality, transfer_id = key

        ((result[inventory_id] ||= {})[[name, category, unit]] ||= []) << {
          quality: quality,
          quantity: quantity,
          inventory_transfer_id: transfer_id
        }
      end
    end

    # The column an entry names its inventory by, which is the one thing the
    # two ledgers spell differently.
    def self.ledger_column(ledger)
      (ledger == ::InventoryItem) ? :inventory_id : :fleet_inventory_id
    end

    def initialize(contract, preloaded: nil)
      @contract = contract
      @preloaded = preloaded
    end

    def summary
      units = lines.map { |line| line.item.unit }.uniq

      Summary.new(
        fraction.to_f,
        lines.sum(0.to_d, &:delivered),
        lines.sum(0.to_d, &:requested),
        units.one? ? units.first : nil,
        complete?
      )
    end

    def lines
      @lines ||= @contract.fleet_contract_items.ordered.map { |item| build_line(item) }
    end

    def complete?
      lines.any? && lines.all?(&:complete?)
    end

    # One number for a progress bar: the mean of the per-line fractions, so a
    # contract asking for two things is half done when one of them is.
    def fraction
      return 0.to_d if lines.empty?

      lines.sum(0.to_d, &:fraction) / lines.size
    end

    # Each line contributes at most 1, split between the contractors in
    # proportion to what each of them put into it; the reward divides by these.
    def weights
      @weights ||= lines.each_with_object(Hash.new(0.to_d)) do |line, result|
        line.contributions.each { |contribution| result[contribution.user_id] += contribution.weight }
      end
    end

    def total_weight
      weights.values.sum(0.to_d)
    end

    private def build_line(item)
      identity = item.position_identity
      delivered_rows = deposits.fetch(identity, [])

      # The line decides, because it also decides *how* -- at or above the
      # grade, or exactly it.
      counted = delivered_rows.select { |row| item.quality_satisfied_by?(row[:quality]) }

      LineProgress.new(
        item: item,
        requested: item.quantity,
        delivered: counted.sum(0.to_d) { |row| row[:quantity] },
        picked_up: withdrawals.fetch(identity, []).sum(0.to_d) { |row| row[:quantity] },
        contributions: contributions_for(item, counted)
      )
    end

    private def contributions_for(item, rows)
      by_user = rows.each_with_object(Hash.new(0.to_d)) do |row, result|
        user_id = contractor_for(row[:inventory_transfer_id])
        next if user_id.blank?

        result[user_id] += row[:quantity]
      end

      total = by_user.values.sum(0.to_d)
      return [] if total.zero?

      # The line is worth 1 however much was delivered into it, so an
      # over-delivered line is scaled back rather than paying more than it asked.
      scale = [item.quantity / total, 1.to_d].min

      by_user.map do |user_id, quantity|
        Contribution.new(
          user_id: user_id,
          delivered: quantity,
          weight: item.quantity.zero? ? 0.to_d : (quantity * scale) / item.quantity
        )
      end
    end

    # Whose goods these were. Read from the column the link wrote at creation,
    # which is the only record that survives the source inventory being deleted
    # -- and never from `initiated_by`, because an officer dispatching on a
    # member's behalf is not the contributor.
    #
    # The live source is still consulted as a fallback, for any transfer linked
    # before the column existed.
    private def contractor_for(transfer_id)
      transfer = transfers_by_id[transfer_id]
      return if transfer.blank?
      return transfer.fleet_contract_contributor_id if transfer.fleet_contract_contributor_id.present?

      party = ::InventoryTransfer.party_of(transfer.source)

      party.id if party.is_a?(::User)
    end

    private def transfers_by_id
      @transfers_by_id ||= if @preloaded
        @preloaded[:transfers].index_by(&:id)
      else
        @contract.inventory_transfers
          .includes(source_inventory: {}, source_fleet_inventory: {})
          .index_by(&:id)
      end
    end

    private def deposits
      @deposits ||= delivered_into.each_with_object({}) do |(inventory_id, transfer_ids), result|
        ledger = @contract.hangar_destination? ? ::InventoryItem : ::FleetInventoryItem

        rollup(inventory_id, :deposit, ledger: ledger).each do |identity, rows|
          own = rows.select { |row| transfer_ids.include?(row[:inventory_transfer_id]) }
          (result[identity] ||= []).concat(own) if own.any?
        end
      end
    end

    # Each inventory deliveries count in, with the transfers whose deposits
    # there count. Only the destination's own ledger: an addressed transfer is
    # accepted by its recipient, and the resolver keeps that inside the
    # recipient's inventories.
    private def delivered_into
      transfers_by_id.values.each_with_object({}) do |transfer, result|
        inventory_id = if @contract.hangar_destination?
          transfer.destination_inventory_id
        else
          transfer.destination_fleet_inventory_id
        end
        next if inventory_id.blank?
        next unless inventory_id == destination_id || addressed_to_destination?(transfer)

        (result[inventory_id] ||= Set.new) << transfer.id
      end
    end

    private def destination_id
      @contract.destination_inventory_id || @contract.destination_fleet_inventory_id
    end

    private def addressed_to_destination?(transfer)
      if @contract.hangar_destination?
        transfer.recipient_id.present? && transfer.recipient_id == @contract.created_by_id
      else
        transfer.recipient_fleet_id.present? && transfer.recipient_fleet_id == @contract.fleet_id
      end
    end

    # Netted, not summed. A refused pickup keeps its withdrawal and adds a
    # compensating deposit back into the source, so counting
    # withdrawals alone would keep reporting goods as being in a courier's hold
    # after they were returned.
    private def withdrawals
      @withdrawals ||= if @contract.requires_pickup?
        net_rollup(@contract.source_fleet_inventory_id)
      else
        {}
      end
    end

    # The same shape as `rollup`, with deposits subtracting rather than being a
    # separate bucket: at the source of a contract a deposit can only be goods
    # coming back.
    private def net_rollup(inventory_id)
      return {} if inventory_id.blank?

      dispatched = rollup(inventory_id, :withdrawal)
      returned = rollup(inventory_id, :deposit)

      dispatched.each_with_object({}) do |(identity, rows), result|
        returned_rows = returned.fetch(identity, [])

        result[identity] = rows.map do |row|
          # Matched per grade, not per transfer. `TransferExecutor#dispatch`
          # writes one withdrawal per quality the line is spent across and
          # `return_to_source` mirrors each of them, so a transfer that took two
          # grades has a return for each -- subtracting the transfer's whole
          # return from every grade would count it once per grade.
          refund = returned_rows
            .select do |other|
              other[:inventory_transfer_id] == row[:inventory_transfer_id] &&
                other[:quality] == row[:quality]
            end
            .sum(0.to_d) { |other| other[:quantity] }

          row.merge(quantity: [row[:quantity] - refund, 0.to_d].max)
        end
      end
    end

    # This contract's share of a page-wide rollup: the rows written into one of
    # its ends *by one of its own transfers*. Both halves matter -- two
    # contracts delivering into the same fleet inventory would otherwise read
    # each other's deliveries as their own.
    private def sliced_rollup(inventory_id, entry_type)
      by_identity = ((entry_type == :deposit) ? @preloaded[:deposits] : @preloaded[:withdrawals])
        .fetch(inventory_id, {})
      own_transfer_ids = transfers_by_id.keys.to_set

      by_identity.each_with_object({}) do |(identity, rows), result|
        own = rows.select { |row| own_transfer_ids.include?(row[:inventory_transfer_id]) }
        result[identity] = own if own.any?
      end
    end

    # Grouped down to one row per position, grade and transfer. Keyed by the
    # same downcased triple `FleetContractItem#position_identity` produces, so a
    # deposit entered as "titanium" answers a contract written as "Titanium".
    private def rollup(inventory_id, entry_type, ledger: ::FleetInventoryItem)
      return {} if inventory_id.blank?
      return sliced_rollup(inventory_id, entry_type) if @preloaded

      rows = ledger
        .where(self.class.ledger_column(ledger) => inventory_id, :entry_type => entry_type)
        .where(inventory_transfer_id: transfers_by_id.keys)
        .group(Arel.sql("LOWER(name)"), :category, :unit, :quality, :inventory_transfer_id)
        .sum(:quantity)

      rows.each_with_object({}) do |(key, quantity), result|
        name, category, unit, quality, transfer_id = key
        identity = [name, category, unit]

        (result[identity] ||= []) << {
          quality: quality,
          quantity: quantity,
          inventory_transfer_id: transfer_id
        }
      end
    end
  end
end
