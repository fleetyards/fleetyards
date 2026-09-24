# frozen_string_literal: true

require "test_helper"

module Discord
  class WeeklyDigestDispatchJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet, default_timezone: "UTC")
      @setting = @fleet.create_fleet_notification_setting!(discord_digest_weekday: 1, discord_digest_time: "18:00")
    end

    test "queues a due digest once, however many ticks find it" do
      travel_to Time.utc(2026, 9, 21, 18, 5) do
        PostWeeklyDigestJob.expects(:perform_async).with(@fleet.id).once

        WeeklyDigestDispatchJob.new.perform
        WeeklyDigestDispatchJob.new.perform
      end

      assert_not_nil @setting.reload.discord_digest_sent_at
    end

    test "queues nothing before the slot" do
      travel_to Time.utc(2026, 9, 21, 17, 55) do
        PostWeeklyDigestJob.expects(:perform_async).never

        WeeklyDigestDispatchJob.new.perform
      end
    end

    test "queues nothing for a fleet with the digest off" do
      @setting.update!(discord_digest_weekday: nil, discord_digest_time: nil)

      travel_to Time.utc(2026, 9, 21, 18, 5) do
        PostWeeklyDigestJob.expects(:perform_async).never

        WeeklyDigestDispatchJob.new.perform
      end
    end

    test "queues nothing for a deleted fleet" do
      @fleet.update_column(:discarded_at, Time.current)

      travel_to Time.utc(2026, 9, 21, 18, 5) do
        PostWeeklyDigestJob.expects(:perform_async).never

        WeeklyDigestDispatchJob.new.perform
      end
    end

    test "gives the week back when the post cannot be queued" do
      travel_to Time.utc(2026, 9, 21, 18, 5) do
        PostWeeklyDigestJob.stubs(:perform_async).raises(RedisClient::CannotConnectError)

        assert_raises(RedisClient::CannotConnectError) { WeeklyDigestDispatchJob.new.perform }
      end

      assert_nil @setting.reload.discord_digest_sent_at
    end
  end
end
