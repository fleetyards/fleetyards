# frozen_string_literal: true

module Contracts
  # How far a contract has actually got, read out of the transfer ledger.
  #
  # Nothing is stored. Delivered quantity is a sum over the deposits that
  # transfers naming this contract wrote into its destination inventory, and
  # those deposits only exist once a transfer was accepted -- a declined,
  # cancelled or expired one compensates back into its *source* (#4878 D2), so
  # it contributes nothing here without any state having to be consulted.
  #
  # Two queries, not two per line: the entries are aggregated in the database
  # down to one row per (position, quality, transfer) and bucketed into lines in
  # Ruby, because the quality threshold differs per line and a per-line query
  # would be N round trips to apply it.
  class Progress
    # What a contractor delivered against one line, and what it is worth when
    # the reward is divided (D6).
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

    def initialize(contract)
      @contract = contract
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

    # D6. Each line contributes at most 1, split between the contractors in
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
      threshold = item.required_quality

      counted = delivered_rows.select { |row| meets_quality?(row, threshold) }

      LineProgress.new(
        item: item,
        requested: item.quantity,
        delivered: counted.sum(0.to_d) { |row| row[:quantity] },
        picked_up: withdrawals.fetch(identity, []).sum(0.to_d) { |row| row[:quantity] },
        contributions: contributions_for(item, counted)
      )
    end

    # A line with no threshold counts every grade, including entries recorded
    # with no quality at all -- which is most of them, since quality is optional
    # on a ledger entry.
    private def meets_quality?(row, threshold)
      return true if threshold.blank?

      row[:quality].present? && row[:quality] >= threshold
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
      @transfers_by_id ||= @contract.inventory_transfers
        .includes(source_inventory: {}, source_fleet_inventory: {})
        .index_by(&:id)
    end

    private def deposits
      @deposits ||= rollup(@contract.destination_fleet_inventory_id, :deposit)
    end

    # Netted, not summed. A refused pickup keeps its withdrawal and adds a
    # compensating deposit back into the source (#4878 D2), so counting
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

    # Grouped down to one row per position, grade and transfer. Keyed by the
    # same downcased triple `FleetContractItem#position_identity` produces, so a
    # deposit entered as "titanium" answers a contract written as "Titanium".
    private def rollup(inventory_id, entry_type)
      return {} if inventory_id.blank?

      rows = ::FleetInventoryItem
        .where(fleet_inventory_id: inventory_id, entry_type: entry_type)
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
