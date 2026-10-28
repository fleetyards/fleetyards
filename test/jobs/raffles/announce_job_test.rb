# frozen_string_literal: true

require "test_helper"

module Raffles
  class AnnounceJobTest < ActiveSupport::TestCase
    setup do
      Sidekiq::Worker.clear_all
      @raffle = create(:raffle, starts_at: 1.hour.ago, run_days: 3)
      @users = create_list(:user, 2)
    end

    test "announces an opened raffle to every user and posts it, once" do
      AnnounceJob.new.perform
      AnnounceBatchJob.drain

      assert_equal @users.size, Notification.where(notification_type: "raffle_started", record_id: @raffle.id).where(user: @users).count
      assert_equal [[@raffle.id, "start"]], PostSocialJob.jobs.map { |job| job["args"] }

      AnnounceJob.new.perform
      assert_equal 1, PostSocialJob.jobs.size
    end

    test "reminds users who have not entered on the last day" do
      create(:raffle_entry, raffle: @raffle, user: @users.first)

      travel 2.days + 2.hours do
        AnnounceJob.new.perform
        AnnounceBatchJob.drain
      end

      reminded = Notification.where(notification_type: "raffle_last_day", record_id: @raffle.id)
      assert_not reminded.exists?(user: @users.first)
      assert reminded.exists?(user: @users.last)
      assert_includes PostSocialJob.jobs.map { |job| job["args"] }, [@raffle.id, "last_day"]
    end

    test "a retried batch writes nothing twice" do
      AnnounceBatchJob.new.perform(@raffle.id, "raffle_started", @users.map(&:id))
      AnnounceBatchJob.new.perform(@raffle.id, "raffle_started", @users.map(&:id))

      assert_equal @users.size, Notification.where(notification_type: "raffle_started", record_id: @raffle.id).count
    end
  end
end
