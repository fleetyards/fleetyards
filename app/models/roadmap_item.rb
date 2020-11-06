# frozen_string_literal: true

# == Schema Information
#
# Table name: roadmap_items
#
#  id                  :uuid             not null, primary key
#  active              :boolean
#  body                :text
#  completed           :integer
#  description         :text
#  image               :string
#  inprogress          :integer
#  name                :string
#  release             :string
#  release_description :text
#  released            :boolean
#  store_image         :string
#  tasks               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  model_id            :uuid
#  rsi_category_id     :integer
#  rsi_id              :integer
#  rsi_release_id      :integer
#
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
    max_created_at = (Time.zone.now + 1.day).to_date if max_created_at.nil?
    versions.where('created_at < ?', max_created_at).last
  end

  def last_version_changed_at(max_created_at = nil)
    max_created_at = (Time.zone.now + 1.day).to_date if max_created_at.nil?
    last_version(max_created_at)&.created_at || created_at
  end
end
