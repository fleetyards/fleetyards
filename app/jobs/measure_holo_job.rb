# frozen_string_literal: true

# Reads a holo's bounding box and writes it to the columns that holo describes.
#
# Out of band because the file has to be fetched whole -- the Mercury's export
# is 18 MB -- and because a failed measurement must not take the upload with it.
class MeasureHoloJob
  include Sidekiq::Worker

  sidekiq_options queue: "preprocessing", retry: 3

  # Which raw glTF axis is the length, the beam and the height. The export
  # pipeline puts every holo in this one frame, confirmed by comparing a
  # ship's flight holo against its landed or extended one: the length holds
  # still on z while the pose moves the other two. So the axes are read rather
  # than guessed -- `HoloDimensions::Result#sorted` guesses, by calling the
  # largest axis the length, and a hull exported with its wings deployed is
  # wider than it is long.
  AXIS_ORDER = %i[z x y].freeze

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

    dimensions = AXIS_ORDER.map { |axis| result.public_send(axis) }
    model.update_columns(columns.zip(dimensions).to_h.merge(measured_at_for(name)))

    write_pad_class(model, name, dimensions)
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
  # The flying box answers for every ship nobody has measured landed, which
  # today is all but one of them, and for one measured only partly -- a landed
  # length with no beam is not a box anything can be classified by.
  #
  # Written as its own conditional statement rather than merged into the write
  # above: the check and the write have to be the same operation, or a landed
  # job finishing in between has its answer overwritten by a flying one that
  # was computed before it landed.
  #
  # The measurement wins over whatever was recorded before. The values it
  # replaces were derived from the RSI matrix and the game files, and those
  # disagree with each other and with the pad table; a number read off the mesh
  # does not.
  #
  # A ground vehicle has no pad class. It is on its own ladder, `vehicle_size`,
  # which is curated rather than measured.
  private def write_pad_class(model, name, dimensions)
    return unless %w[holo landed_holo].include?(name)
    return if model.size == ::Model::VEHICLE_SIZE

    pad = ::Dock.ship_size_for(*dimensions)
    return if pad.nil?

    scope = ::Model.where(id: model.id)
    scope = scope.where(INCOMPLETE_LANDED_BOX) if name == "holo"

    scope.update_all(dock_size: ::Model.dock_sizes.fetch(pad))
  end

  INCOMPLETE_LANDED_BOX = "landed_length IS NULL OR landed_beam IS NULL OR landed_height IS NULL"

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
