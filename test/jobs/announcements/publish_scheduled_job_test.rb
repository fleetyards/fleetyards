# frozen_string_literal: true

require "test_helper"

module Announcements
  class PublishScheduledJobTest < ActiveJob::TestCase
    test "#perform publishes only what is due" do
      due = create(:announcement, status: "scheduled", publish_at: 1.minute.ago)
      create(:announcement, status: "scheduled", publish_at: 1.hour.from_now)
      create(:announcement)

      # Flagged as a sweep run, which is what holds it to re-checking due-ness.
      Announcements::PublishJob.expects(:perform_async).with(due.id, true).once

      Announcements::PublishScheduledJob.new.perform
    end
  end
end
