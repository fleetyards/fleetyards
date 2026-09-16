# frozen_string_literal: true

module Announcements
  # Splits the reader list into batches and hands each one to its own job.
  #
  # Split rather than looped, because the work is ~57k inserts and ~57k
  # broadcasts: one job holding all of it occupies a worker for minutes and
  # loses everything it had done if it dies halfway.
  class FanOutJob < Announcements::BaseJob
    def perform(announcement_id)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?

      # One evaluation of the audience, not a count and then a walk. Two
      # queries can disagree -- an account deleted between them leaves a
      # recipients_count no batch can ever reach, and because the in-app
      # delivery only settles when the notifications match it, it would sit
      # pending for good.
      #
      # ~57k ids is a few megabytes in a job that is about to write 57k rows.
      user_ids = User.confirmed.pluck(:id)

      # Written before a single batch is queued: it is what a batch compares
      # its own progress against, and it would be nil for whichever batch got
      # there first.
      announcement.update!(recipients_count: user_ids.size)

      user_ids.each_slice(Announcement::FAN_OUT_BATCH_SIZE) do |batch|
        Announcements::NotifyBatchJob.perform_async(announcement.id, batch)
      end
    end
  end
end
