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

    measured = columns.zip(result.sorted).to_h

    model.update_columns(measured.merge(measured_at_for(name)).merge(pad_class_for(model, name, result)))
  rescue ActiveStorage::FileNotFoundError
    Rails.logger.warn("MeasureHoloJob: blob for #{name} on model #{model_id} not found, skipping")
  rescue JSON::ParserError => error
    Rails.logger.warn("MeasureHoloJob: #{name} on model #{model_id} is not readable glTF: #{error.message}")
  end

  # Which pad the hull lands on, from the box just measured -- and it lands with
  # its gear down and its wings wherever landing mode puts them, so the landed
  # box is the one that decides. The Arrow folds its wings up to extend the
  # gear: narrower than in flight, and taller, which is what keeps it out of a
  # Carrack bay it would otherwise clear.
  #
  # The flying box still answers for the ships nobody has measured landed, which
  # today is all but one of them. It does not overwrite a landed answer.
  #
  # The measurement wins over whatever was recorded before. The values it
  # replaces were derived from the RSI matrix and the game files, and those
  # disagree with each other and with the pad table; a number read off the mesh
  # does not.
  #
  # A ground vehicle has no pad class. It is on its own ladder, `vehicle_size`,
  # which is curated rather than measured.
  private def pad_class_for(model, name, result)
    return {} unless %w[holo landed_holo].include?(name)
    return {} if model.size == ::Model::VEHICLE_SIZE
    return {} if name == "holo" && model.landed_length.present?

    length, beam, height = result.sorted
    pad = ::Dock.ship_size_for(length, beam, height)

    pad.nil? ? {} : {dock_size: pad}
  end

  # Only reached once a measurement is actually being written, which is the
  # whole value of the stamp: a refused export or an overtaken correction
  # returns above and leaves the previous one standing.
  private def measured_at_for(name)
    column = ::Model::HOLO_MEASURED_AT[name]
    return {} if column.nil?

    {column => Time.current}
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
