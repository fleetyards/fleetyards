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
    where enabled: true
  end

  def to_jq_upload
    {
      'name' => self[:name],
      'size' => name.size,
      'url' => name.url,
      'enabled' => enabled,
      'background' => background,
      'thumbnailUrl' => name.small.url,
      'toggleUrl' => toggle_admin_image_path(id: id),
      'toggleBackgroundUrl' => toggle_background_admin_image_path(id: id),
      'deleteUrl' => admin_image_path(id: id),
      'deleteType' => 'DELETE'
    }
  end
end
