# frozen_string_literal: true

class Image < ApplicationRecord
  paginates_per 16

  include Rails.application.routes.url_helpers
  belongs_to :gallery, polymorphic: true, touch: true

  mount_uploader :name, ImageUploader

  def to_jq_upload
    {
      "name" => self[:name],
      "size" => name.size,
      "url" => name.url,
      "thumbnailUrl" => name.small.url,
      "deleteUrl" => backend_image_path(id: id),
      "deleteType" => "DELETE"
    }
  end

  def self.in_gallery
    where("gallery_id IS NOT ?", nil)
  end

  def self.enabled
    where enabled: true
  end
end
