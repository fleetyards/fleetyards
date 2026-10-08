# frozen_string_literal: true

class MarkdownImage < ApplicationRecord
  include ActiveStorageVariants

  CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_BYTE_SIZE = 10.megabytes
  DAILY_LIMIT = 100
  DISPLAY_SIZE = :large

  # Every text a description image can be embedded in. An image stays while
  # one of them names it -- the current text, or, for a type whose history an
  # admin can revert a field from, any recorded version of it.
  REFERENCING_COLUMNS = {
    "Fleet" => %i[description],
    "FleetContract" => %i[description],
    "FleetEvent" => %i[description briefing],
    "FleetEventOccurrenceState" => %i[description briefing],
    "FleetEventShip" => %i[description],
    "FleetEventTeam" => %i[description],
    "FleetSquadron" => %i[description],
    "Mission" => %i[description],
    "MissionShip" => %i[description],
    "MissionTeam" => %i[description]
  }.freeze

  # Time to save the form an image was inserted into, before an image no text
  # names counts as abandoned.
  UNREFERENCED_GRACE = 7.days

  REFERENCE_PATTERN = "markdown-images/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"

  # Nil once the uploader's account is gone; the image stays while text uses it.
  belongs_to :user, optional: true

  has_one_attached :file

  before_validation :analyze_file, on: :create

  validates :user, presence: true, on: :create
  validates :file, presence: true, no_vector_image: true
  validate :file_not_attached_elsewhere, on: :create
  validate :file_is_a_supported_image
  validate :file_within_size_limit
  validate :daily_limit_not_reached, on: :create

  def self.referenced_ids
    ids = REFERENCING_COLUMNS.flat_map do |class_name, columns|
      model = class_name.constantize

      columns.flat_map do |column|
        quoted = model.connection.quote_column_name(column)

        ids_in(model.unscoped.where("#{quoted} ILIKE ?", "%markdown-images/%"), quoted)
      end
    end

    ids.concat(ids_in_history).to_set
  end

  def self.unreferenced
    where(created_at: ..UNREFERENCED_GRACE.ago).where.not(id: referenced_ids.to_a)
  end

  # Case-insensitive, and lowered to how ids are stored: an address with an
  # uppercase id resolves all the same, so it has to count all the same.
  private_class_method def self.ids_in(scope, expression)
    scope.pluck(Arel.sql("lower((regexp_matches(#{expression}, '#{REFERENCE_PATTERN}', 'gi'))[1])"))
  end

  # Only the history of records that still exist: an admin reverts a field on a
  # live record, and a deleted one's versions would otherwise keep its images
  # forever. A purged fleet is the exception -- Fleets::PurgedFleetRestorer
  # rebuilds it, description included, from its destroy snapshot.
  private_class_method def self.ids_in_history
    history = "concat(object::text, object_changes::text, old_object, old_object_changes)"

    live = (REFERENCING_COLUMNS.keys & ::VersionedItem::TYPES).flat_map do |class_name|
      ids_in(
        PaperTrail::Version
          .where(item_type: class_name, item_id: class_name.constantize.unscoped.select(:id))
          .where("#{history} ILIKE ?", "%markdown-images/%"),
        history
      )
    end

    # The latest snapshot only, as the restorer uses: an older one can no longer
    # come back, and would hold its images forever. Snapshots can share that
    # latest second, and nothing breaks the tie the same way on both sides, so
    # all of them count.
    latest = PaperTrail::Version
      .select(:item_id, "MAX(versions.created_at)")
      .where(item_type: "Fleet", event: "destroy")
      .where.not(item_id: Fleet.unscoped.select(:id))
      .group(:item_id)
    restorable = PaperTrail::Version
      .select(:id)
      .where(item_type: "Fleet", event: "destroy")
      .where("(versions.item_id, versions.created_at) IN (#{latest.to_sql})")

    live + ids_in(
      PaperTrail::Version
        .where(id: restorable)
        .where("object::text ILIKE ?", "%markdown-images/%"),
      "object::text"
    )
  end

  def display_representation
    file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[DISPLAY_SIZE])
  end

  # The representation is scaled down to fit its bounds, never up, so this is
  # the size of the picture the URL actually serves.
  def display_dimensions
    width = file.metadata[:width]
    height = file.metadata[:height]
    return [width, height] if width.blank? || height.blank?

    max_width, max_height = ActiveStorageVariants::REPRESENTATION_SIZES[DISPLAY_SIZE][:resize_to_limit]
    scale = [max_width.to_f / width, max_height.to_f / height, 1].min

    [(width * scale).round, (height * scale).round]
  end

  # A direct upload's content type is whatever the client declared. Reading the
  # dimensions decodes the file, so a blob that is not the raster image it
  # claims to be comes back without them. A file attached from an IO is not
  # stored yet, but ActiveStorage identifies its type from the bytes instead.
  private def analyze_file
    return unless file.attached?

    blob = file.blob
    # Analysing downloads the file, and a direct upload is not size-limited:
    # anything over the limit is refused by its size without being fetched.
    return if blob.byte_size > MAX_BYTE_SIZE

    blob.analyze if blob.persisted? && !blob.analyzed?
  rescue ActiveStorage::FileNotFoundError
    nil
  end

  # A signed blob id is not secret -- the API hands out the ones behind logos and
  # covers -- so an upload must be one nothing else uses. Taking over another
  # record's blob would publish its file, and deleting this image would purge it
  # from under that record.
  private def file_not_attached_elsewhere
    return unless file.attached?
    return if file.blob.new_record?
    return unless ActiveStorage::Attachment.where(blob_id: file.blob.id).where.not(record: self).exists?

    errors.add(:file, :file_in_use)
  end

  private def file_is_a_supported_image
    return unless file.attached?
    return if CONTENT_TYPES.include?(file.content_type) && (file.metadata[:width].present? || file.blob.new_record?)

    errors.add(:file, :image_type_not_supported)
  end

  private def file_within_size_limit
    return unless file.attached?
    return if file.byte_size <= MAX_BYTE_SIZE

    errors.add(:file, :file_too_large, count: MAX_BYTE_SIZE / 1.megabyte)
  end

  private def daily_limit_not_reached
    return if user.blank?
    return if user.markdown_images.where(created_at: 24.hours.ago..).count < DAILY_LIMIT

    errors.add(:base, :markdown_image_limit_reached, count: DAILY_LIMIT)
  end
end
