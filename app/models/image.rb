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

  include Rails.application.routes.url_helpers
  belongs_to :gallery, polymorphic: true, touch: true, counter_cache: true

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

  def self.global_enabled
    where(global: true)
  end

  def self.background
    where(background: true)
  end
end
