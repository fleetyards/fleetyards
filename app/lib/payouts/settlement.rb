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
  #   share   = profit / participant count
  #   balance = (income they hold - expenses they paid) - share
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

    def initialize(ledger)
      @ledger = ledger
      @participants = ledger.payout_participants.order(:created_at, :id).to_a
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

    # An even split almost never divides evenly, and dropping the remainder
    # would leave the balances summing to something other than zero -- which
    # means a transfer list that cannot exist. The largest-remainder method
    # hands the leftover hundredths out one each, in a stable participant order
    # so the same ledger always settles identically. Ordering by id after the
    # remainder is what keeps it stable; ordering by remainder alone would let
    # ties fall wherever the hash happened to enumerate.
    private def shares_by_participant_id
      count = @participants.size
      return {} if count.zero?

      base, remainder = profit_minor.divmod(count)

      # divmod on a negative profit floors, so `base` is already the smaller
      # share and `remainder` is a non-negative count of participants who take
      # one hundredth more. That is the same shape as the positive case, so no
      # branch on the sign is needed.
      ordered_ids = @participants.map(&:id)

      ordered_ids.each_with_index.to_h do |id, index|
        [id, base + ((index < remainder) ? 1 : 0)]
      end
    end

    private def to_minor(amount)
      (amount.to_d * SCALE).round.to_i
    end

    private def to_decimal(minor)
      (minor.to_d / SCALE).round(2)
    end
  end
end
