# frozen_string_literal: true

# One stretch of time a model was on sale. An open row -- `ended_at` nil -- is
# a sale still running.
# == Schema Information
#
# Table name: model_sales
#
#  id         :uuid             not null, primary key
#  ended_at   :datetime
#  started_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  model_id   :uuid             not null
#
# Indexes
#
#  index_model_sales_on_model_id                 (model_id)
#  index_model_sales_on_model_id_and_started_at  (model_id,started_at) UNIQUE
#  index_model_sales_on_model_id_ongoing         (model_id) UNIQUE WHERE (ended_at IS NULL)
#  index_model_sales_on_started_at               (started_at)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
class ModelSale < ApplicationRecord
  belongs_to :model

  scope :ongoing, -> { where(ended_at: nil) }
  scope :finished, -> { where.not(ended_at: nil) }
  scope :recent_first, -> { order(started_at: :desc) }

  validates :started_at, presence: true
  validate :ended_after_started

  def ongoing?
    ended_at.blank?
  end

  # Nil while the sale is still running: an open-ended stretch has no length,
  # and reporting "so far" as a duration would read as a finished sale.
  def duration_in_days
    return if ongoing?

    ((ended_at - started_at) / 1.day).round(1)
  end

  private def ended_after_started
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, :invalid)
  end
end
