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

    test "gives the week back once its retries are spent" do
      @setting.update!(discord_digest_sent_at: Time.current)

      PostWeeklyDigestJob.sidekiq_retries_exhausted_block.call({"args" => [@fleet.id]}, StandardError.new)

      assert_nil @setting.reload.discord_digest_sent_at
    end
  end
end
