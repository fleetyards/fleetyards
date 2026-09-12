# frozen_string_literal: true

# Reads a holo's bounding box and writes it to the columns that holo describes.
#
# Out of band because the file has to be fetched whole -- the Mercury's export
# is 18 MB -- and because a failed measurement must not take the upload with it.
class MeasureHoloJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 3

  def perform(model_id, name)
    columns = ::Model::HOLO_DIMENSIONS[name]
    return if columns.blank?

    model = ::Model.find_by(id: model_id)
    attachment = model&.send(name)
    return unless attachment&.attached?

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

    model.update_columns(columns.zip(result.sorted).to_h)
  rescue ActiveStorage::FileNotFoundError
    Rails.logger.warn("MeasureHoloJob: blob for #{name} on model #{model_id} not found, skipping")
  rescue JSON::ParserError => error
    Rails.logger.warn("MeasureHoloJob: #{name} on model #{model_id} is not readable glTF: #{error.message}")
  end
end
