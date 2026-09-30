# frozen_string_literal: true

# == Schema Information
#
# Table name: markdown_images
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_markdown_images_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class MarkdownImage < ApplicationRecord
  include ActiveStorageVariants

  CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_BYTE_SIZE = 10.megabytes
  DAILY_LIMIT = 100
  DISPLAY_SIZE = :large

  belongs_to :user

  has_one_attached :file

  before_validation :analyze_file, on: :create

  validates :file, presence: true, no_vector_image: true
  validate :file_is_a_supported_image
  validate :file_within_size_limit
  validate :daily_limit_not_reached, on: :create

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
