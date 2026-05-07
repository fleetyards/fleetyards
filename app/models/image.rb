# frozen_string_literal: true

# == Schema Information
#
# Table name: images
#
#  id           :uuid             not null, primary key
#  background   :boolean          default(TRUE)
#  caption      :string
#  enabled      :boolean          default(FALSE), not null
#  gallery_name :string
#  gallery_slug :string
#  gallery_type :string(255)
#  global       :boolean          default(TRUE)
#  created_at   :datetime
#  updated_at   :datetime
#  gallery_id   :uuid
#
# Indexes
#
#  index_images_on_gallery_id  (gallery_id)
#
class Image < ApplicationRecord
  include ActiveStorageVariants

  paginates_per 30

  belongs_to :gallery, polymorphic: true, touch: true, counter_cache: true, optional: true

  belongs_to :model,
    -> { includes(:images).where(images: {gallery_type: "Model"}) },
    foreign_key: "gallery_id",
    inverse_of: :images,
    optional: true

  has_one_attached :file

  ransack_alias :model, :model_slug

  before_validation :set_gallery_fields

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = [
    "createdAt asc", "createdAt desc", "updatedAt asc", "updatedAt desc",
    "enabled asc", "enabled desc"
  ].freeze

  def self.ransackable_attributes(auth_object = nil)
    [
      "background", "caption", "created_at", "enabled", "gallery_id", "gallery_type", "global",
      "id", "id_value", "model", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["gallery", "model"]
  end

  def self.in_gallery
    where.not(gallery_id: nil)
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

  def set_gallery_fields
    self.gallery_name = gallery&.name
    self.gallery_slug = gallery&.slug
  end
end
