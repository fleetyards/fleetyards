# frozen_string_literal: true

# == Schema Information
#
# Table name: progress_tracker_items
#
#  id                :uuid             not null, primary key
#  description       :string
#  discipline_counts :integer
#  end_date          :date
#  key               :string
#  projects          :string
#  start_date        :date
#  team              :string
#  time_allocations  :string
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  model_id          :uuid
#
# Indexes
#
#  index_progress_tracker_items_on_key  (key) UNIQUE
#
class ProgressTrackerItem < ApplicationRecord
  serialize :projects
  serialize :time_allocations

  has_paper_trail on: %i[create update]

  belongs_to :model, optional: true

  validates :key, uniqueness: true, presence: true

  after_save :update_model_production_status

  def update_model_production_status
    return if model_id.blank?
    return if model.production_status == 'flight-ready'
    return if start_date > Time.current

    model.update(production_status: 'in-production')
  end
end
