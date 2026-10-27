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
      assert @second.reload.claim_deadline_at > 13.days.from_now
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

    test "passes over entrants whose account is gone or unconfirmed" do
      @second.update_columns(user_id: nil, username: "gone")
      @third.user.update_columns(confirmed_at: nil)

      assert_nil Succession.new(@raffle).call

      assert @second.reload.forfeited_at.present?
      assert_nil @second.won_at
      assert @third.reload.forfeited_at.present?
      assert @raffle.reload.concluded?
    end

    test "the job advances every raffle with an expired claim" do
      Raffles::SuccessionJob.new.perform

      assert_equal @second, @raffle.current_winner
    end
  end
end
