# frozen_string_literal: true

# == Schema Information
#
# Table name: progress_tracker_items
#
#  id                :uuid             not null, primary key
#  deleted_at        :datetime
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
  paginates_per 30

  serialize :projects
  serialize :time_allocations

  has_paper_trail on: %i[create update]

  belongs_to :model, optional: true

  validates :key, uniqueness: true, presence: true

  after_save :update_model_production_status

  searchkick searchable: %i[title],
             word_start: %i[title]

  scope :search_import, -> { where(deleted_at: nil) }

  def search_data
    {
      title: title,
      start_date: start_date,
      end_date: end_date,
      team: team,
      in_progress: in_progress?,
      done: done?,
      planned: planned?,
      model_id: model_id,
      with_model: model_id.present?
    }
  end

  def status
    if planned?
      :planned
    elsif in_progress?
      :in_progress
    elsif done?
      :done
    end
  end

  def status_label
    ProgressTrackerItem.human_enum_name(:status, status)
  end

  def planned?
    start_date > Time.current
  end

  def in_progress?
    start_date < Time.current && end_date > Time.current
  end

  def done?
    end_date < Time.current
  end

  def should_index?
    !deleted?
  end

  def deleted?
    deleted_at.present?
  end

  def update_model_production_status
    return if model_id.blank?
    return if model.production_status == 'flight-ready'
    return if planned?

    model.update(production_status: 'in-production')
  end
end
