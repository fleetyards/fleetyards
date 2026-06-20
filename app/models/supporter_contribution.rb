# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id           :uuid             not null, primary key
#  amount_cents :integer          not null
#  anonymous    :boolean          default(FALSE), not null
#  currency     :string           default("EUR"), not null
#  ended_at     :date
#  name         :string
#  note         :text
#  recurring    :boolean          default(FALSE), not null
#  started_at   :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_supporter_contributions_on_recurring_and_ended_at  (recurring,ended_at)
#  index_supporter_contributions_on_started_at              (started_at)
#
class SupporterContribution < ApplicationRecord
  paginates_per 30

  DEFAULT_SORTING_PARAMS = "started_at desc"
  ALLOWED_SORTING_PARAMS = [
    "startedAt asc", "startedAt desc",
    "endedAt asc", "endedAt desc",
    "amountCents asc", "amountCents desc",
    "name asc", "name desc",
    "createdAt asc", "createdAt desc"
  ]

  validates :amount_cents, presence: true, numericality: {greater_than: 0, only_integer: true}
  validates :currency, presence: true
  validates :started_at, presence: true
  validate :ended_at_after_started_at

  before_validation :force_anonymous_when_name_blank

  scope :active_in, ->(month_start, month_end) {
    where(
      "(recurring = ? AND started_at BETWEEN ? AND ?) OR " \
      "(recurring = ? AND started_at <= ? AND (ended_at IS NULL OR ended_at >= ?))",
      false, month_start, month_end,
      true, month_end, month_start
    )
  }

  def self.ransackable_attributes(auth_object = nil)
    [
      "name", "amount_cents", "currency", "anonymous", "recurring",
      "started_at", "ended_at", "note", "created_at", "updated_at", "id"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.monthly_total(date = Date.current)
    month_start = date.beginning_of_month
    month_end = date.end_of_month
    active_in(month_start, month_end).sum(:amount_cents)
  end

  private def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, :must_be_after_started_at)
  end

  private def force_anonymous_when_name_blank
    self.anonymous = true if name.blank?
  end
end
