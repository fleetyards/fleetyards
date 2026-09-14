# frozen_string_literal: true

require "test_helper"

module Payouts
  class SettlementTest < ActiveSupport::TestCase
    setup do
      @ledger = create(:payout_ledger)
    end

    # Every case below has to hold these three, so they are asserted together
    # rather than restated each time. The zero-sum one is the load-bearing
    # invariant: a transfer list can only exist if what is owed and what is
    # owing cancel out exactly.
    def assert_settles(settlement, participants)
      balances = settlement.balances
      transfers = settlement.transfers

      assert_equal 0, balances.sum(&:net), "balances do not sum to zero"

      if participants.any?
        assert_operator transfers.size, :<=, participants.size - 1,
          "more transfers than the participant count allows"
      end

      assert(transfers.all? { |transfer| transfer.amount.positive? },
        "a transfer moved a non-positive amount")

      moved = Hash.new(0)
      transfers.each do |transfer|
        moved[transfer.from_participant.id] += transfer.amount
        moved[transfer.to_participant.id] -= transfer.amount
      end

      balances.each do |balance|
        assert_equal balance.net, moved[balance.participant.id],
          "#{balance.participant.display_name} is left unsettled"
      end
    end

    def balance_for(settlement, participant)
      settlement.balances.find { |balance| balance.participant.id == participant.id }
    end

    test "reimburses the payer before sharing the profit" do
      alice = create(:payout_participant, payout_ledger: @ledger)
      bob = create(:payout_participant, payout_ledger: @ledger)
      cara = create(:payout_participant, payout_ledger: @ledger)

      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: bob, amount: 900_000)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: alice, amount: 12_000)

      settlement = Settlement.new(@ledger)

      assert_equal 888_000, settlement.profit
      assert_equal 296_000, balance_for(settlement, cara).share

      # Alice is out of pocket 12,000 and owed a 296,000 share on top.
      assert_equal(-308_000, balance_for(settlement, alice).net)
      assert_equal 604_000, balance_for(settlement, bob).net
      assert_equal(-296_000, balance_for(settlement, cara).net)

      assert_settles(settlement, [alice, bob, cara])
    end

    test "distributes a profit that does not divide evenly" do
      participants = create_list(:payout_participant, 3, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger,
        payout_participant: participants.first, amount: 100)

      settlement = Settlement.new(@ledger)

      shares = settlement.balances.map(&:share)

      # 100 / 3 leaves a hundredth over; it goes to exactly one participant
      # rather than being dropped, so the shares still add back up to the profit.
      assert_equal 100, shares.sum
      assert_equal [33.34, 33.33, 33.33], shares
      assert_settles(settlement, participants)
    end

    test "splits a pure expense tour with no income" do
      alice, bob, cara = create_list(:payout_participant, 3, payout_ledger: @ledger)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: alice, amount: 90)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: bob, amount: 30)

      settlement = Settlement.new(@ledger)

      assert_equal(-120, settlement.profit)
      assert_equal(-50, balance_for(settlement, alice).net)
      assert_equal 10, balance_for(settlement, bob).net
      assert_equal 40, balance_for(settlement, cara).net

      assert_settles(settlement, [alice, bob, cara])
    end

    test "gives a share to a participant who recorded nothing" do
      earner = create(:payout_participant, payout_ledger: @ledger)
      idle = create(:payout_participant, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: earner, amount: 1000)

      settlement = Settlement.new(@ledger)

      assert_equal 500, balance_for(settlement, idle).share
      assert_equal(-500, balance_for(settlement, idle).net)
      assert_settles(settlement, [earner, idle])
    end

    test "gives a guest a share like anyone else" do
      member = create(:payout_participant, payout_ledger: @ledger)
      guest = create(:payout_participant, :guest, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: member, amount: 300)

      settlement = Settlement.new(@ledger)

      assert_predicate guest, :guest?
      assert_equal 150, balance_for(settlement, guest).share
      assert_settles(settlement, [member, guest])
    end

    test "leaves a single participant with nothing to send" do
      alice = create(:payout_participant, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: alice, amount: 500)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: alice, amount: 200)

      settlement = Settlement.new(@ledger)

      assert_equal 0, balance_for(settlement, alice).net
      assert_empty settlement.transfers
    end

    test "handles a ledger with no participants" do
      settlement = Settlement.new(@ledger)

      assert_empty settlement.balances
      assert_empty settlement.transfers
      assert_equal 0, settlement.profit
    end

    test "moves nothing when everyone is already even" do
      participants = create_list(:payout_participant, 2, payout_ledger: @ledger)
      participants.each do |participant|
        create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: participant, amount: 100)
      end

      settlement = Settlement.new(@ledger)

      assert_empty settlement.transfers
      assert_settles(settlement, participants)
    end

    test "keeps fractional amounts exact" do
      alice, bob, cara = create_list(:payout_participant, 3, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: alice, amount: 10.01)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: bob, amount: 3.33)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: cara, amount: 0.01)

      settlement = Settlement.new(@ledger)

      assert_equal 6.67, settlement.profit
      assert_equal 6.67, settlement.balances.sum(&:share)
      assert_settles(settlement, [alice, bob, cara])
    end

    test "totals expenses and income separately" do
      alice, bob = create_list(:payout_participant, 2, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: alice, amount: 700)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: bob, amount: 250)

      settlement = Settlement.new(@ledger)

      assert_equal 700, settlement.total_income
      assert_equal 250, settlement.total_expenses
      assert_equal 450, settlement.profit
    end

    test "settles a seven way split with a messy remainder" do
      participants = create_list(:payout_participant, 7, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: participants[0], amount: 1_000_000)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[1], amount: 77_777)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[2], amount: 3)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: participants[3], amount: 11)

      settlement = Settlement.new(@ledger)

      assert_equal settlement.profit, settlement.balances.sum(&:share)
      assert_settles(settlement, participants)
    end

    # Two runs over the same ledger have to agree, or settling would hand out a
    # different list each time it was previewed.
    test "produces identical transfers on repeated runs" do
      participants = create_list(:payout_participant, 4, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: participants[0], amount: 1000)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[1], amount: 333)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[2], amount: 1)

      first = Settlement.new(@ledger.reload).transfers
      second = Settlement.new(@ledger.reload).transfers

      assert_equal first.map { |t| [t.from_participant.id, t.to_participant.id, t.amount] },
        second.map { |t| [t.from_participant.id, t.to_participant.id, t.amount] }
    end

    # The whole point of the column: a tour where somebody joined for the last
    # run only. Three full shares and a half share out of 3,000,000.
    test "gives a reduced weight a smaller share" do
      hazard = create(:payout_participant, payout_ledger: @ledger)
      ruby = create(:payout_participant, payout_ledger: @ledger)
      tamsin = create(:payout_participant, payout_ledger: @ledger)
      vex = create(:payout_participant, payout_ledger: @ledger, weight: 0.5)

      create(:payout_entry, payout_ledger: @ledger, payout_participant: hazard, amount: 1_200_000)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: ruby, amount: 2_400_000)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: tamsin, amount: 1_800_000)

      settlement = Settlement.new(@ledger)

      assert_equal 3_000_000, settlement.profit
      assert_equal 428_571.43, balance_for(settlement, vex).share

      # The three full shares are 857,142.86 / .86 / .85 -- which of them takes
      # the spare hundredth depends on participant order, so they are asserted
      # as a set rather than one by one.
      full_shares = [hazard, ruby, tamsin].map { |participant| balance_for(settlement, participant).share }

      assert_equal [857_142.85, 857_142.86, 857_142.86], full_shares.sort
      assert_equal settlement.profit, settlement.balances.sum(&:share)
      assert_settles(settlement, [hazard, ruby, tamsin, vex])
    end

    # A weight divides the profit and nothing else. Vex paid for the fuel and
    # gets all of it back before any share is worked out, even at half a share.
    test "reimburses a reduced-weight participant in full" do
      alice = create(:payout_participant, payout_ledger: @ledger)
      vex = create(:payout_participant, payout_ledger: @ledger, weight: 0.5)

      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: alice, amount: 30_000)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: vex, amount: 6_000)

      settlement = Settlement.new(@ledger)

      assert_equal 24_000, settlement.profit
      assert_equal 8_000, balance_for(settlement, vex).share

      # 6,000 back, plus 8,000 of the profit.
      assert_equal(-14_000, balance_for(settlement, vex).net)
      assert_settles(settlement, [alice, vex])
    end

    # Symmetric on purpose: half a share of the winnings is half a share of the
    # damage. Integer division floors either way, so there is no branch on the
    # sign for this to have missed.
    test "divides a loss by weight as well" do
      alice = create(:payout_participant, payout_ledger: @ledger)
      vex = create(:payout_participant, payout_ledger: @ledger, weight: 0.5)

      create(:payout_entry, payout_ledger: @ledger, payout_participant: alice, amount: 90_000)

      settlement = Settlement.new(@ledger)

      assert_equal(-90_000, settlement.profit)
      assert_equal(-60_000, balance_for(settlement, alice).share)
      assert_equal(-30_000, balance_for(settlement, vex).share)
      assert_equal 30_000, balance_for(settlement, vex).net
      assert_settles(settlement, [alice, vex])
    end

    # The regression guard for every ledger already open when this shipped.
    test "splits identically to an unweighted ledger when every weight is one" do
      participants = create_list(:payout_participant, 7, payout_ledger: @ledger)
      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: participants[0], amount: 1_000_000)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[1], amount: 77_777)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[2], amount: 3)

      settlement = Settlement.new(@ledger)
      shares = settlement.balances.map(&:share)

      # 922,220 over seven is 131,745.71 with a remainder of three hundredths.
      assert_equal [131_745.71] * 4 + [131_745.72] * 3, shares.sort
      assert_equal settlement.profit, shares.sum
      assert_settles(settlement, participants)
    end

    test "lets a weight above one take more than a full share" do
      alice = create(:payout_participant, payout_ledger: @ledger)
      bob = create(:payout_participant, payout_ledger: @ledger, weight: 2)

      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: alice, amount: 30_000)

      settlement = Settlement.new(@ledger)

      assert_equal 10_000, balance_for(settlement, alice).share
      assert_equal 20_000, balance_for(settlement, bob).share
      assert_settles(settlement, [alice, bob])
    end

    # Weights that share no common factor with the profit are where a naive
    # rounding loses hundredths, and the balances stop summing to zero.
    test "keeps a weighted remainder exact" do
      participants = [
        create(:payout_participant, payout_ledger: @ledger, weight: 0.33),
        create(:payout_participant, payout_ledger: @ledger, weight: 0.67),
        create(:payout_participant, payout_ledger: @ledger, weight: 1.11),
        create(:payout_participant, payout_ledger: @ledger, weight: 0.07)
      ]

      create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: participants[0], amount: 777_777.77)
      create(:payout_entry, payout_ledger: @ledger, payout_participant: participants[1], amount: 111_111.11)

      settlement = Settlement.new(@ledger)

      assert_equal settlement.profit, settlement.balances.sum(&:share)
      assert_settles(settlement, participants)
    end
  end
end
