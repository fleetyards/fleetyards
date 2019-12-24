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

  def self.global_enabled
    where(global: true)
  end

  def self.background
    where(background: true)
  end
end
