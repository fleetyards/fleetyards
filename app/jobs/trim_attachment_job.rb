# frozen_string_literal: true

class TrimAttachmentJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 5

  # A job enqueued before the side views were renamed still names them so.
  def self.current_name(attachment_name)
    attachment_name.to_s.sub("side_view", "port_view")
  end

  # A crop that never lands must still leave the pending list, or the admin
  # waiting on it sees a view that is processing for good.
  sidekiq_retries_exhausted do |job, _error|
    record_class, record_id, attachment_name = job["args"]

    record_class.safe_constantize&.find_by(id: record_id)&.settle_trim(current_name(attachment_name))
  end

  # ActiveStorage uploads the file in its own after_commit, which runs after the
  # one that enqueues this job, so the first attempt can arrive before the bytes
  # do. ActiveStorage::FileNotFoundError is deliberately left to raise: a retry
  # picks the file up seconds later, where swallowing it would leave the padding
  # in place for good.
  def perform(record_class, record_id, attachment_name)
    record = record_class.safe_constantize&.find_by(id: record_id)
    return if record.nil?

    attachment_name = self.class.current_name(attachment_name)
    trim(record.public_send(attachment_name))
    record.settle_trim(attachment_name)
  end

  private

  def trim(attachment)
    return unless attachment&.attached?
    return if AttachmentTrimmer.new(attachment).call

    # Nothing was cropped, so no new blob arrives to trigger preprocessing.
    PreprocessRepresentationsJob.perform_async(attachment.blob.id)
  end
end
