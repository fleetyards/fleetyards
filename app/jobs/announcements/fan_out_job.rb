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

      # Counted and written before a single batch is queued, because that is
      # what a batch compares its own progress against when it decides whether
      # it was the last one. Written afterwards it would be nil for the batches
      # that got there first.
      announcement.update!(recipients_count: User.confirmed.count)

      User.confirmed.in_batches(of: Announcement::FAN_OUT_BATCH_SIZE) do |batch|
        Announcements::NotifyBatchJob.perform_async(announcement.id, batch.pluck(:id))
      end
    end
  end
end
