# frozen_string_literal: true

# == Schema Information
#
# Table name: images
#
#  id           :uuid             not null, primary key
#  background   :boolean          default(TRUE)
#  caption      :string
#  enabled      :boolean          default(FALSE), not null
#  gallery_type :string(255)
#  global       :boolean          default(TRUE)
#  height       :integer
#  name         :string(255)
#  width        :integer
#  created_at   :datetime
#  updated_at   :datetime
#  gallery_id   :uuid
#
# Indexes
#
#  index_images_on_gallery_id  (gallery_id)
#
class Image < ApplicationRecord
  paginates_per 30

  belongs_to :gallery, polymorphic: true, touch: true, counter_cache: true

  belongs_to :model,
    -> { includes(:images).where(images: {gallery_type: "Model"}) },
    foreign_key: "gallery_id",
    inverse_of: :images,
    optional: true

  belongs_to :station,
    -> { includes(:images).where(images: {gallery_type: "Station"}) },
    foreign_key: "gallery_id",
    inverse_of: :images,
    optional: true

  mount_uploader :name, ImageUploader

  ransack_alias :model, :model_slug
  ransack_alias :station, :station_slug

  def self.ransackable_attributes(auth_object = nil)
    [
      "background", "caption", "created_at", "enabled", "gallery_id", "gallery_type", "global",
      "height", "id", "id_value", "model", "name", "station", "updated_at", "width"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["gallery", "model", "station"]
  end

  def self.in_gallery
    where("gallery_id IS NOT ?", nil)
  end

  def self.with_uniq_name
    where(id: Image.select("distinct on (name) id"))
  end

  def self.enabled
    where(enabled: true)
  end

  def self.global_enabled
    where(global: true)
  end

  def self.background
    where(background: true)
  end
end
