# frozen_string_literal: true

class PrefillImageGalleryFields < ActiveRecord::Migration[7.2]
  def up
    Image.where(gallery_type: "Station").update_all(gallery_type: nil, gallery_id: nil)

    Image.find_each do |image|
      next if image.gallery.blank?

      image.set_gallery_fields

      image.save!
    end
  end
end
