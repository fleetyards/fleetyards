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
    end

    # The batches decide that, once every reader has a row. Marking it here
    # would call the fan-out finished the moment it was queued.
    test "#perform does not mark the in-app delivery succeeded" do
      create(:user)
      announcement = create(:announcement)
      Announcements::NotifyBatchJob.stubs(:perform_async)

      Announcements::FanOutJob.new.perform(announcement.id)

      refute announcement.deliveries.exists?(status: "succeeded")
    end

    # The count and the batches used to be two queries. An account leaving the
    # scope between them left a recipients_count no batch could reach, and the
    # in-app delivery settles only when the two match -- so it sat pending for
    # good.
    test "#perform counts the audience it actually queued" do
      create_list(:user, 3)
      announcement = create(:announcement)

      queued = []
      Announcements::NotifyBatchJob.stubs(:perform_async).with do |_id, ids|
        queued.concat(ids)
        true
      end

      Announcements::FanOutJob.new.perform(announcement.id)

      assert_equal queued.size, announcement.reload.recipients_count
    end

    test "#perform ignores a missing announcement" do
      Announcements::NotifyBatchJob.expects(:perform_async).never

      assert_nothing_raised { Announcements::FanOutJob.new.perform(SecureRandom.uuid) }
    end
  end
end
