# frozen_string_literal: true

# == Schema Information
#
# Table name: funding_goals
#
#  id             :uuid             not null, primary key
#  amount_cents   :integer          not null
#  currency       :string           default("EUR"), not null
#  description    :text
#  effective_from :date             not null
#  ended_at       :date
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_funding_goals_on_effective_from  (effective_from)
#  index_funding_goals_on_ended_at        (ended_at)
#
class FundingGoal < ApplicationRecord
  attr_accessor :update_reason, :update_reason_description, :author_id

  # Only an admin action sets `author_id`, so a loader write files nothing. The
  # gate is not tidiness: the UEX sync rewrites all 232 commodities and 1,526 of
  # 4,830 equipment rows a week, and versioning those unconditionally would bury
  # the handful of real edits the way Fleet's touch versions already do.
  has_paper_trail on: %i[update],
    only: %i[
      title description amount_cents currency effective_from ended_at
    ],
    if: ->(record) { record.author_id.present? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
  paginates_per 30

  DEFAULT_SORTING_PARAMS = "effective_from desc"
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "effectiveFrom asc", "effectiveFrom desc",
    "amountCents asc", "amountCents desc",
    "createdAt asc", "createdAt desc"
  ]

  validates :title, presence: true
  validates :amount_cents, presence: true, numericality: {greater_than: 0, only_integer: true}
  validates :currency, presence: true
  validates :effective_from, presence: true
  validate :ended_at_after_effective_from

  scope :active_on, ->(date) {
    where("effective_from <= ?", date)
      .where("ended_at IS NULL OR ended_at >= ?", date)
  }

  def self.ransackable_attributes(auth_object = nil)
    ["title", "amount_cents", "currency", "effective_from", "ended_at", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.active_for_month(date = Date.current)
    active_on(date).order(effective_from: :desc, created_at: :desc)
  end

  def self.monthly_total(date = Date.current)
    active_on(date).sum(:amount_cents)
  end

  private def ended_at_after_effective_from
    return if ended_at.blank? || effective_from.blank?
    return if ended_at >= effective_from

    errors.add(:ended_at, :must_be_after_effective_from)
  end
end
