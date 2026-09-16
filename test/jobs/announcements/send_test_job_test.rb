# frozen_string_literal: true

require "test_helper"
require "discord/announcement_preview"

module Announcements
  class SendTestJobTest < ActiveJob::TestCase
    test "#perform posts the preview and records when it ran" do
      announcement = create(:announcement, :social)
      ::Discord::AnnouncementPreview.stubs(:configured?).returns(true)
      ::Discord::AnnouncementPreview.expects(:new).with(announcement: announcement).returns(stub(run: true))

      Announcements::SendTestJob.new.perform(announcement.id)

      assert announcement.reload.last_tested_at.present?
    end

    # The dry run is a dry run: nothing about the announcement moves, and no
    # channel records a delivery.
    test "#perform leaves the announcement and its deliveries alone" do
      announcement = create(:announcement, :social)
      ::Discord::AnnouncementPreview.stubs(:configured?).returns(true)
      ::Discord::AnnouncementPreview.stubs(:new).returns(stub(run: true))

      Announcements::SendTestJob.new.perform(announcement.id)

      assert announcement.reload.status_draft?
      assert_equal 0, announcement.deliveries.count
      assert_equal 0, Notification.where(notification_type: "announcement").count
    end

    test "#perform does nothing without an admin webhook" do
      announcement = create(:announcement)
      ::Discord::AnnouncementPreview.stubs(:configured?).returns(false)
      ::Discord::AnnouncementPreview.expects(:new).never

      Announcements::SendTestJob.new.perform(announcement.id)

      assert_nil announcement.reload.last_tested_at
    end

    test "#perform ignores a missing announcement" do
      assert_nothing_raised { Announcements::SendTestJob.new.perform(SecureRandom.uuid) }
    end
  end
end
