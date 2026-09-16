# frozen_string_literal: true

require "test_helper"

module Announcements
  class FanOutJobTest < ActiveJob::TestCase
    test "#perform batches the confirmed readers and records how many there were" do
      create_list(:user, 2)
      create(:user, confirmed_at: nil)
      announcement = create(:announcement)

      batched = []
      Announcements::NotifyBatchJob.stubs(:perform_async).with do |_id, user_ids|
        batched.concat(user_ids)
        true
      end

      Announcements::FanOutJob.new.perform(announcement.id)

      assert_equal User.confirmed.count, batched.size
      assert_equal User.confirmed.count, announcement.reload.recipients_count
      assert announcement.delivery_for(:in_app).reload.status_succeeded?
    end

    test "#perform ignores a missing announcement" do
      Announcements::NotifyBatchJob.expects(:perform_async).never

      assert_nothing_raised { Announcements::FanOutJob.new.perform(SecureRandom.uuid) }
    end
  end
end
