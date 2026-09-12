# frozen_string_literal: true

# Reads a holo's bounding box and writes it to the columns that holo describes.
#
# Out of band because the file has to be fetched whole -- the Mercury's export
# is 18 MB -- and because a failed measurement must not take the upload with it.
class MeasureHoloJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 3

  # The blob the attachment carried when this was queued. A second upload while
  # the first is still in the queue would otherwise let the older file's
  # measurements land on the newer holo, and whichever job finished last would
  # decide.
  def perform(model_id, name, blob_id = nil)
    columns = ::Model::HOLO_DIMENSIONS[name]
    return if columns.blank?

    model = ::Model.find_by(id: model_id)
    attachment = model&.send(name)
    return unless attachment&.attached?
    return if blob_id.present? && attachment.blob.id != blob_id

    result = ::HoloDimensions.from_blob(attachment.blob)
    return if result.nil?

    # An export whose rotation is off the axes bounds the rotated box rather
    # than the hull, so the numbers would be an upper bound presented as a
    # measurement. The re-exported Pisces and Mercury are both exact; one that
    # is not needs looking at rather than recording.
    unless result.exact
      Rails.logger.warn(
        "MeasureHoloJob: #{name} on model #{model_id} has a rotation off the axes, not recorded"
      )
      return
    end

    # Still the same blob after the read, which for a large file is not
    # instant. Re-read rather than trusting the attachment loaded above.
    return if blob_id.present? && model.reload.send(name).blob&.id != blob_id

    model.update_columns(columns.zip(result.sorted).to_h)
  rescue ActiveStorage::FileNotFoundError
    Rails.logger.warn("MeasureHoloJob: blob for #{name} on model #{model_id} not found, skipping")
  rescue JSON::ParserError => error
    Rails.logger.warn("MeasureHoloJob: #{name} on model #{model_id} is not readable glTF: #{error.message}")
  end
end
