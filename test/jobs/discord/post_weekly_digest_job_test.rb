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

    # Monday's claim, but the digest was moved to Tuesday before it ran.
    test "drops a claim the schedule has moved away from, and gives it back" do
      claimed_at = Time.utc(2026, 9, 21, 18, 5)
      @setting.update!(discord_digest_sent_at: claimed_at, discord_digest_weekday: 2)
      WeeklyDigest.any_instance.expects(:run).never

      PostWeeklyDigestJob.new.perform(@fleet.id, claimed_at.iso8601(6))

      assert_nil @setting.reload.discord_digest_sent_at
    end

    test "posts a claim the schedule still answers" do
      claimed_at = Time.utc(2026, 9, 21, 18, 5)
      @setting.update!(discord_digest_sent_at: claimed_at)
      WeeklyDigest.any_instance.expects(:run)

      travel_to(claimed_at + 1.minute) { PostWeeklyDigestJob.new.perform(@fleet.id, claimed_at.iso8601(6)) }
    end

    test "posts nothing when it runs days after its slot" do
      claimed_at = Time.utc(2026, 9, 21, 18, 5)
      @setting.update!(discord_digest_sent_at: claimed_at)
      WeeklyDigest.any_instance.expects(:run).never

      travel_to(claimed_at + 3.days) { PostWeeklyDigestJob.new.perform(@fleet.id, claimed_at.iso8601(6)) }
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
