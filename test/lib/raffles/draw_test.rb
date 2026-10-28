# frozen_string_literal: true

require "test_helper"

module Raffles
  class DrawTest < ActiveSupport::TestCase
    setup do
      @raffle = create(:raffle)
      @entries = create_list(:raffle_entry, 3, raffle: @raffle)
      @raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)
      @admin = create(:admin_user)
    end

    test "orders every confirmed entrant and makes the first the winner" do
      result = Draw.new(@raffle, admin_user: @admin).call

      assert_equal :drawn, result.status
      assert_equal [1, 2, 3], @raffle.entries.order(:draw_position).pluck(:draw_position)
      assert_equal 1, result.winner.draw_position
      assert result.winner.claim_deadline_at.between?(2.days.from_now, 4.days.from_now)
      assert_equal @admin, @raffle.reload.drawn_by
    end

    test "notifies the winner and queues the claim mail" do
      result = nil

      assert_difference -> { Notification.where(notification_type: "raffle_won").count }, 1 do
        assert_difference -> { Raffles::ClaimMailJob.jobs.size }, 1 do
          result = Draw.new(@raffle, admin_user: @admin).call
        end
      end

      assert_equal result.winner.user, Notification.find_by(notification_type: "raffle_won").user
      assert_equal [result.winner.id], Raffles::ClaimMailJob.jobs.last["args"]
    end

    test "leaves unconfirmed entrants out of the order" do
      @entries.first.user.update_columns(confirmed_at: nil)

      Draw.new(@raffle, admin_user: @admin).call

      assert_nil @entries.first.reload.draw_position
      assert_equal 2, @raffle.entries.where.not(draw_position: nil).count
    end

    test "refuses a raffle that is still open" do
      @raffle.update_columns(ends_at: 1.day.from_now)

      assert_equal :not_closed, Draw.new(@raffle, admin_user: @admin).call.status
    end

    test "refuses to draw twice" do
      Draw.new(@raffle, admin_user: @admin).call

      assert_equal :already_drawn, Draw.new(@raffle, admin_user: @admin).call.status
    end

    test "refuses a raffle without eligible entrants" do
      @raffle.entries.delete_all

      assert_equal :no_entrants, Draw.new(@raffle, admin_user: @admin).call.status
      assert_not @raffle.reload.drawn?
    end
  end
end
