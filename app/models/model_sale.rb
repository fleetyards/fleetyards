# frozen_string_literal: true

# One stretch of time a model was on sale. An open row -- `ended_at` nil -- is
# a sale still running.
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
