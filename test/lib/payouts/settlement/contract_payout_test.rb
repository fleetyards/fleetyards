# frozen_string_literal: true

require "test_helper"

module Payouts
  class Settlement
    class ContractPayoutTest < ActiveSupport::TestCase
      setup do
        @ledger = create(:payout_ledger)
        @fleet = create(:payout_participant, :fleet, payout_ledger: @ledger)
      end

      def settle
        Settlement.new(@ledger, rule: ContractPayout)
      end

      def balance_for(settlement, participant)
        settlement.balances.find { |balance| balance.participant.id == participant.id }
      end

      test "divides the reward across the contractors by weight" do
        lead = create(:payout_participant, payout_ledger: @ledger, weight: 1.5)
        crew = create(:payout_participant, payout_ledger: @ledger, weight: 0.5)
        create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @fleet, amount: 100_000)

        settlement = settle

        assert_equal 75_000, balance_for(settlement, lead).share
        assert_equal 25_000, balance_for(settlement, crew).share
        assert_equal 0, balance_for(settlement, @fleet).share
        assert_equal 0, settlement.balances.sum(&:net)
      end

      test "reimburses a contractor's expense on top of the reward" do
        lead = create(:payout_participant, payout_ledger: @ledger)
        crew = create(:payout_participant, payout_ledger: @ledger)
        create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @fleet, amount: 100_000)
        create(:payout_entry, payout_ledger: @ledger, payout_participant: lead, amount: 20_000)

        settlement = settle

        # Under an equal split the expense would come out of the reward and
        # leave each contractor 40,000; here the reward stays whole.
        assert_equal 50_000, balance_for(settlement, lead).share
        assert_equal 50_000, balance_for(settlement, crew).share
        assert_equal(-70_000, balance_for(settlement, lead).net)
        assert_equal(-50_000, balance_for(settlement, crew).net)
        assert_equal 120_000, balance_for(settlement, @fleet).net

        transfers = settlement.transfers
        assert(transfers.all? { |transfer| transfer.from_participant.id == @fleet.id })
        assert_equal 120_000, transfers.sum(&:amount)
      end

      test "keeps the shares summing to the profit when the reward does not divide" do
        contractors = create_list(:payout_participant, 3, payout_ledger: @ledger)
        create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @fleet, amount: 100)

        settlement = settle

        assert_equal [33.34, 33.33, 33.33], contractors.map { |contractor| balance_for(settlement, contractor).share }
        assert_equal 0, settlement.balances.sum(&:net)
      end

      test "falls back to an equal split while nobody but the fleet is on the ledger" do
        create(:payout_entry, :income, payout_ledger: @ledger, payout_participant: @fleet, amount: 1_000)

        settlement = settle

        assert_equal 1_000, balance_for(settlement, @fleet).share
        assert_empty settlement.transfers
      end
    end
  end
end
