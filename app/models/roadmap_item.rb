# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  MODELS_CATEGORY = 6

  has_paper_trail on: %i[create update], only: %i[release tasks completed active]

  belongs_to :model, optional: true

  mount_uploader :store_image, StoreImageUploader

  ransack_alias :last_updated_at, :versions_created_at

  def self.activen
    where(active: true)
  end

  def last_version(max_created_at = nil)
    max_created_at = Time.zone.now.to_date if max_created_at.nil?
    versions.where('created_at < ?', max_created_at).last
  end

  def last_version_changed_at(max_created_at = nil)
    max_created_at = Time.zone.now.to_date if max_created_at.nil?
    last_version(max_created_at)&.created_at || created_at
  end
end
