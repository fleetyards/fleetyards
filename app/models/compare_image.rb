# frozen_string_literal: true

# == Schema Information
#
# Table name: compare_images
#
#  id         :uuid             not null, primary key
#  slug_set   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_compare_images_on_slug_set  (slug_set) UNIQUE
#
class CompareImage < ApplicationRecord
  has_one_attached :image

  validates :slug_set, presence: true, uniqueness: true

  def self.for(models)
    models_with_images = models.select { |m| m.store_image.attached? }
    return nil if models_with_images.empty?

    slug_set = models_with_images.map(&:slug).sort.join("-")
    record = find_or_initialize_by(slug_set: slug_set)
    record.generate!(models_with_images) unless record.image.attached?
    record
  end

  def generate!(models)
    buffer = build_composite(models)
    return if buffer.nil?

    image.attach(
      io: StringIO.new(buffer),
      filename: "#{slug_set}.jpg",
      content_type: "image/jpeg"
    )
    save!
  rescue ActiveRecord::RecordNotUnique
    # Another worker created the row between find_or_initialize_by and save.
    # The next request will pick up their attachment from the cache.
  end

  private def build_composite(models)
    require "vips"

    images = models.filter_map do |model|
      next unless model.store_image.attached?

      Vips::Image.new_from_buffer(model.store_image.download, "")
    end
    return nil if images.empty?

    base = images.first
    slice_width = base.width / images.size

    slices = images.map { |img| img.thumbnail_image(slice_width, height: base.height, crop: :centre) }
    Vips::Image.arrayjoin(slices).jpegsave_buffer
  end
end
