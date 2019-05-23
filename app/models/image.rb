# frozen_string_literal: true

class Image < ApplicationRecord
  paginates_per 30

  include Rails.application.routes.url_helpers
  belongs_to :gallery, polymorphic: true, touch: true

  mount_uploader :name, ImageUploader

  def self.in_gallery
    where('gallery_id IS NOT ?', nil)
  end

  def self.with_uniq_name
    where(id: Image.select('distinct on (name) id'))
  end

  def self.enabled
    where(enabled: true)
  end

  def self.background
    where(background: true)
  end

  def dimensions
    dimensions = []
    dimensions = ::MiniMagick::Image.open(name.file.file)[:dimensions] if dimensions_missing?
    OpenStruct.new(
      width: width || dimensions[0],
      height: height || dimensions[1]
    )
  end

  private def dimensions_missing?
    (width.blank? || height.blank?) && File.exist?(name.file.file)
  end
end
