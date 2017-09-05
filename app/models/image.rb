# frozen_string_literal: true

class Image < ApplicationRecord
  paginates_per 48

  include Rails.application.routes.url_helpers
  belongs_to :gallery, polymorphic: true, touch: true

  mount_uploader :name, ImageUploader

  def to_jq_upload
    {
      "name" => self[:name],
      "size" => name.size,
      "url" => name.url,
      "enabled" => self[:enabled],
      "thumbnailUrl" => name.small.url,
      "toggleUrl" => toggle_admin_image_path(id: id),
      "deleteUrl" => admin_image_path(id: id),
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
