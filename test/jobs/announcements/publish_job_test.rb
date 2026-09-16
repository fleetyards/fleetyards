# frozen_string_literal: true

require "test_helper"

module Announcements
  class PublishJobTest < ActiveJob::TestCase
    test "#perform queues every selected channel and marks the announcement published" do
      announcement = create(:announcement, :social)

      Announcements::PostSocialJob.expects(:perform_async).with(announcement.id, "discord").once
      Announcements::PostSocialJob.expects(:perform_async).with(announcement.id, "bluesky").once
      Announcements::PostSocialJob.expects(:perform_async).with(announcement.id, "x").once
      Announcements::FanOutJob.expects(:perform_async).with(announcement.id).once

      Announcements::PublishJob.new.perform(announcement.id)

      announcement.reload
      assert announcement.status_published?
      assert announcement.published_at.present?
      assert_equal %w[bluesky discord in_app x], announcement.deliveries.pluck(:channel).sort
    end

    test "#perform leaves out the channels that were not selected" do
      announcement = create(:announcement, post_bluesky: true)

      Announcements::PostSocialJob.expects(:perform_async).with(announcement.id, "bluesky").once
      Announcements::FanOutJob.expects(:perform_async).once

      Announcements::PublishJob.new.perform(announcement.id)

      assert_equal %w[bluesky in_app], announcement.deliveries.pluck(:channel).sort
    end

    test "#perform does not re-send an announcement that already went out" do
      announcement = create(:announcement, :published)

      Announcements::FanOutJob.expects(:perform_async).never

      Announcements::PublishJob.new.perform(announcement.id)
    end

    test "#perform ignores a missing announcement" do
      assert_nothing_raised { Announcements::PublishJob.new.perform(SecureRandom.uuid) }
    end

    test "#perform marks the announcement failed when dispatch raises" do
      announcement = create(:announcement)
      Announcements::FanOutJob.stubs(:perform_async).raises(StandardError, "boom")

      assert_raises(StandardError) { Announcements::PublishJob.new.perform(announcement.id) }

      assert announcement.reload.status_failed?
    end
  end
end
