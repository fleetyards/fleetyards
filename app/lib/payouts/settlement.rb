# frozen_string_literal: true

module Payouts
  # Works out what every participant of a payout ledger is owed, and the
  # transfers that get everyone there.
  #
  # Costs are reimbursed to whoever paid them before anything is divided, so a
  # participant who funded the tour is made whole first and only the remaining
  # profit is shared. Expressed as a single balance per participant:
  #
  #   profit  = total income - total expenses
  #   share   = profit * their weight / the weights of everyone on the ledger
  #   balance = (income they hold - expenses they paid) - share
  #
  # The weight is what a participant is entitled to relative to the others --
  # 1 for a full share, less for somebody who joined the tour late or left it
  # early. It divides the profit and nothing else: reimbursement is not a share,
  # so a latecomer who paid for the fuel still gets all of it back. A ledger
  # where nobody carries a reduced weight divides exactly as an unweighted one
  # would, which is what lets this ship without moving any existing ledger.
  #
  # A positive balance means they are holding more than their share and have to
  # send the difference on; a negative one means they are owed. The balances sum
  # to zero by construction, which is what makes a transfer list possible at all
  # and is the invariant worth asserting against.
  #
  # Nothing here is written down. While a ledger is open its balances are
  # recomputed on every read, for the reason StockPosition gives for not storing
  # derived totals: a stored copy can drift from the entries it claims to
  # describe, and the entries are the record of truth. PayoutLedger#settle! is
  # the one exception -- it freezes these transfers into rows, because once
  # people start paying against the list it has to stop moving.
  class Settlement
    Balance = Struct.new(:participant, :paid, :held, :share, :net) do
      def owes? = net.positive?

      def owed? = net.negative?
    end

    Transfer = Struct.new(:from_participant, :to_participant, :amount)

    # Every amount is scaled to whole hundredths for the duration of the
    # calculation. The columns are decimal(15, 2) and so exact already, but
    # dividing one by a participant count is not, and integers are the only way
    # to divide, round and re-add without the remainder going missing.
    SCALE = 100

    def self.call(ledger) = new(ledger).call

    def initialize(ledger, rule: self.class.rule_for(ledger))
      @ledger = ledger
      @rule = rule
      @participants = ledger.payout_participants.includes(:user, fleet: {logo_attachment: :blob}).order(:created_at, :id).to_a
      @entries = ledger.payout_entries.to_a
    end

    def call
      {balances: balances, transfers: transfers}
    end

    def balances
      @balances ||= begin
        shares = shares_by_participant_id

        @participants.map do |participant|
          paid = paid_minor.fetch(participant.id, 0)
          held = held_minor.fetch(participant.id, 0)
          share = shares.fetch(participant.id, 0)

          Balance.new(
            participant: participant,
            paid: to_decimal(paid),
            held: to_decimal(held),
            share: to_decimal(share),
            net: to_decimal(held - paid - share)
          )
        end
      end
    end

    # Greedy min-cash-flow: the largest debtor pays the largest creditor as much
    # as the smaller of the two positions allows, which settles at least one of
    # them per step and so needs at most one transfer fewer than there are
    # participants. It is not provably the minimum for every input -- that
    # problem is NP-hard -- but it never produces the obviously silly answer of
    # routing everything through one person.
    def transfers
      @transfers ||= begin
        debtors = net_minor_positions.select { |_id, amount| amount.positive? }
        creditors = net_minor_positions.select { |_id, amount| amount.negative? }

        debtors = debtors.sort_by { |id, amount| [-amount, id] }
        creditors = creditors.sort_by { |id, amount| [amount, id] }

        result = []

        until debtors.empty? || creditors.empty?
          debtor_id, debt = debtors.first
          creditor_id, credit = creditors.first

          amount = [debt, -credit].min

          result << Transfer.new(
            from_participant: participants_by_id.fetch(debtor_id),
            to_participant: participants_by_id.fetch(creditor_id),
            amount: to_decimal(amount)
          )

          debt -= amount
          credit += amount

          debt.zero? ? debtors.shift : debtors[0] = [debtor_id, debt]
          credit.zero? ? creditors.shift : creditors[0] = [creditor_id, credit]
        end

        result
      end
    end

    def total_expenses = to_decimal(paid_minor.values.sum)

    def total_income = to_decimal(held_minor.values.sum)

    def profit = to_decimal(profit_minor)

    private def participants_by_id
      @participants_by_id ||= @participants.index_by(&:id)
    end

    private def paid_minor
      @paid_minor ||= sum_minor_by_participant(:expense)
    end

    private def held_minor
      @held_minor ||= sum_minor_by_participant(:income)
    end

    private def sum_minor_by_participant(entry_type)
      @entries.each_with_object({}) do |entry, result|
        next unless entry.entry_type.to_s == entry_type.to_s

        result[entry.payout_participant_id] =
          result.fetch(entry.payout_participant_id, 0) + to_minor(entry.amount)
      end
    end

    private def profit_minor
      held_minor.values.sum - paid_minor.values.sum
    end

    private def net_minor_positions
      balances.to_h do |balance|
        [balance.participant.id, to_minor(balance.net)]
      end
    end

    private def shares_by_participant_id
      @rule.shares(participants: @participants, profit_minor: profit_minor, expenses_minor: paid_minor.values.sum)
    end

    private def to_minor(amount) = self.class.to_minor(amount)

    private def to_decimal(minor)
      (minor.to_d / SCALE).round(2)
    end

    def self.to_minor(amount)
      (amount.to_d * SCALE).round.to_i
    end

    # A split almost never divides evenly, and dropping the remainder would
    # leave the balances summing to something other than zero -- which means a
    # transfer list that cannot exist. The largest-remainder method hands the
    # leftover hundredths out one each, in a stable participant order so the
    # same ledger always settles identically. Ordering by position after the
    # remainder is what keeps it stable; ordering by remainder alone would let
    # ties fall wherever the array happened to enumerate.
    #
    # The weights are scaled to hundredths for the same reason the amounts are:
    # they are decimal(5, 2) and so exact already, but the division is not, and
    # integers are the only way to divide, round and re-add without the
    # remainder going missing.
    #
    # Returns one share per participant, in the order given.
    def self.divide(total_minor, participants)
      return [] if participants.empty?

      weights = participants.map { |participant| to_minor(participant.weight) }
      total_weight = weights.sum

      # Unreachable while the weight validation holds -- it is strictly
      # positive, so any non-empty list totals more than zero. Here so a
      # malformed row cannot divide by zero rather than as a real branch.
      return Array.new(participants.size, 0) if total_weight.zero?

      # Integer division floors in Ruby, on a negative total too, so each base
      # is already the smaller share and every remainder below is non-negative.
      # That is the same shape the unweighted divmod had, which is why no branch
      # on the sign is needed here either.
      bases = weights.map { |weight| (total_minor * weight) / total_weight }

      remainders = weights.each_with_index.map do |weight, index|
        (total_minor * weight) - (bases[index] * total_weight)
      end

      leftover = total_minor - bases.sum
      largest_first = remainders.each_with_index.sort_by { |remainder, index| [-remainder, index] }.map(&:last)

      shares = bases.dup
      largest_first.first(leftover).each { |index| shares[index] += 1 }
      shares
    end

    # How the profit is divided is the one thing that differs by subject. The
    # rest -- reimbursement, rounding, the transfer pass and the zero-sum
    # invariant -- is the same money moving the same way.
    def self.rule_for(ledger)
      (ledger.subject_type == "FleetContract") ? ContractPayout : EqualShares
    end
  end
end
