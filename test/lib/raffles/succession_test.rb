# frozen_string_literal: true

require "test_helper"

module Raffles
  class SuccessionTest < ActiveSupport::TestCase
    setup do
      @raffle = create(:raffle, :closed, drawn_at: 3.weeks.ago)
      @first, @second, @third = (1..3).map do |position|
        create(:raffle_entry, :after_close, raffle: @raffle, draw_position: position)
      end
      @first.update!(won_at: 3.weeks.ago, claim_deadline_at: 1.week.ago)
    end

    test "forfeits an expired win and promotes the next in line" do
      winner = Succession.new(@raffle).call

      assert_equal @second, winner
      assert @first.reload.forfeited_at.present?
      assert @second.reload.claim_deadline_at > 2.days.from_now
      assert_equal @second, @raffle.current_winner
    end

    test "leaves a win alone while its deadline runs" do
      @first.update!(claim_deadline_at: 1.day.from_now)

      assert_nil Succession.new(@raffle).call
      assert_nil @first.reload.forfeited_at
    end

    test "leaves a claimed win alone" do
      @first.update!(claimed_at: 2.weeks.ago)

      assert_nil Succession.new(@raffle).call
      assert_nil @first.reload.forfeited_at
    end

    test "mails the promoted winner a claim link" do
      winner = Succession.new(@raffle).call

      assert_equal [winner.id], Raffles::ClaimMailJob.jobs.last["args"]
    end

    test "passes over entrants whose account is no longer confirmed" do
      @second.user.update_columns(confirmed_at: nil)
      @third.user.update_columns(confirmed_at: nil)

      assert_nil Succession.new(@raffle).call

      assert @second.reload.forfeited_at.present?
      assert_nil @second.won_at
      assert @third.reload.forfeited_at.present?
      assert @raffle.reload.concluded?
    end

    test "passes over a maintainer" do
      @second.user.update_columns(maintainer: true)

      assert_equal @third, Succession.new(@raffle).call
      assert @second.reload.forfeited_at.present?
      assert_nil @second.won_at
    end

    test "promotes an entrant whose account is gone and mails the entry address" do
      @second.update_columns(user_id: nil, username: "gone")

      winner = Succession.new(@raffle).call

      assert_equal @second, winner
      assert_equal @second.email, winner.recipient_email
      assert_equal [winner.id], Raffles::ClaimMailJob.jobs.last["args"]
    end

    test "the job advances every raffle with an expired claim" do
      Raffles::SuccessionJob.new.perform

      assert_equal @second, @raffle.current_winner
    end
  end
end
