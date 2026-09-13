# frozen_string_literal: true

# Reads a holo's bounding box and writes it to the columns that holo describes.
#
# Out of band because the file has to be fetched whole -- the Mercury's export
# is 18 MB -- and because a failed measurement must not take the upload with it.
class MeasureHoloJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 3

  # What the columns held when the job was queued, as strings: a job's arguments
  # round-trip through JSON and a decimal does not survive that as itself.
  def self.snapshot(model, columns)
    columns.map { |column| model.send(column)&.to_s }
  end

  # `blob_id` and `previous` are what make a late result safe to apply. Both are
  # optional so a job queued by hand still measures.
  def perform(model_id, name, blob_id = nil, previous = nil)
    columns = ::Model::HOLO_DIMENSIONS[name]
    return if columns.blank?

    model = ::Model.find_by(id: model_id)
    attachment = model&.send(name)
    return unless attachment&.attached?
    return if stale_blob?(attachment, blob_id)

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

    # Reading an 18 MB file is not instant, so nothing that was true at the top
    # is still assumed here.
    model.reload
    return if stale_blob?(model.send(name), blob_id)
    return if overtaken?(model, columns, previous)

    model.update_columns(columns.zip(result.sorted).to_h)
  rescue ActiveStorage::FileNotFoundError
    Rails.logger.warn("MeasureHoloJob: blob for #{name} on model #{model_id} not found, skipping")
  rescue JSON::ParserError => error
    Rails.logger.warn("MeasureHoloJob: #{name} on model #{model_id} is not readable glTF: #{error.message}")
  end

  # A second upload while this one was queued: the older file's numbers must not
  # land on the newer holo, whichever job finishes last.
  private def stale_blob?(attachment, blob_id)
    blob_id.present? && attachment&.blob&.id != blob_id
  end

  # Somebody correcting a figure by hand while the file was being fetched would
  # otherwise lose it without being told. A holo is not more right than the
  # person who looked at the ship.
  private def overtaken?(model, columns, previous)
    return false if previous.blank?

    self.class.snapshot(model, columns) != previous
  end
end
