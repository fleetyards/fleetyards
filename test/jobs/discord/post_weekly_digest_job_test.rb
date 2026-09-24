# frozen_string_literal: true

require "test_helper"

module Discord
  class PostWeeklyDigestJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(discord_digest_weekday: 1, discord_digest_time: "18:00")
    end

    test "posts the digest" do
      WeeklyDigest.any_instance.expects(:run)

      PostWeeklyDigestJob.new.perform(@fleet.id)
    end

    test "posts nothing once the digest was switched off" do
      @setting.update!(discord_digest_weekday: nil, discord_digest_time: nil)
      WeeklyDigest.any_instance.expects(:run).never

      PostWeeklyDigestJob.new.perform(@fleet.id)
    end

    test "posts nothing for a deleted fleet" do
      @fleet.update_column(:discarded_at, Time.current)
      WeeklyDigest.any_instance.expects(:run).never

      PostWeeklyDigestJob.new.perform(@fleet.id)
    end

    def exhaust(claimed_at)
      PostWeeklyDigestJob.sidekiq_retries_exhausted_block.call({"args" => [@fleet.id, claimed_at.iso8601(6)]}, StandardError.new)
    end

    test "gives its week back once its retries are spent" do
      claimed_at = Time.current.floor(6)
      @setting.update!(discord_digest_sent_at: claimed_at)

      exhaust(claimed_at)

      assert_nil @setting.reload.discord_digest_sent_at
    end

    # A job that failed slowly must not reopen a week claimed after it.
    test "leaves a later week's claim alone" do
      later = Time.current.floor(6)
      @setting.update!(discord_digest_sent_at: later)

      exhaust(later - 7.days)

      assert_equal later, @setting.reload.discord_digest_sent_at
    end
  end
end
