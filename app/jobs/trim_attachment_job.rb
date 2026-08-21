# frozen_string_literal: true

class TrimAttachmentJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 5

  # ActiveStorage uploads the file in its own after_commit, which runs after the
  # one that enqueues this job, so the first attempt can arrive before the bytes
  # do. ActiveStorage::FileNotFoundError is deliberately left to raise: a retry
  # picks the file up seconds later, where swallowing it would leave the padding
  # in place for good.
  def perform(record_class, record_id, attachment_name)
    record = record_class.safe_constantize&.find_by(id: record_id)
    attachment = record&.public_send(attachment_name)
    return unless attachment&.attached?

    return if AttachmentTrimmer.new(attachment).call

    # Nothing was cropped, so no new blob arrives to trigger preprocessing.
    PreprocessRepresentationsJob.perform_async(attachment.blob.id)
  end
end
