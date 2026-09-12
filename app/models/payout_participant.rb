# frozen_string_literal: true

# == Schema Information
#
# Table name: payout_participants
#
#  id               :uuid             not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  added_by_id      :uuid
#  payout_ledger_id :uuid             not null
#  user_id          :uuid
#
# Indexes
#
#  index_payout_participants_on_payout_ledger_id     (payout_ledger_id)
#  index_payout_participants_unique_user_per_ledger  (payout_ledger_id,user_id) UNIQUE WHERE (user_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (added_by_id => users.id)
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (user_id => users.id)
#
class PayoutParticipant < ApplicationRecord
  belongs_to :payout_ledger, touch: true
  belongs_to :user, optional: true
  belongs_to :added_by, class_name: "User", optional: true

  has_many :payout_entries, dependent: :restrict_with_error

  # Someone on the tour without a FleetYards account is named rather than
  # linked, which is the only way the payout list can account for them at all.
  # SupporterContribution carries the same pair for the same reason.
  validates :name, presence: true, if: -> { user_id.blank? }
  validates :user_id, uniqueness: {scope: :payout_ledger_id}, allow_nil: true

  before_destroy :check_for_entries, prepend: true

  def guest? = user_id.blank?

  def display_name
    user&.username.presence || name
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[payout_ledger_id user_id name created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[payout_ledger user payout_entries]
  end

  # Removing someone re-divides the profit across everyone who is left, so a
  # participant who has already recorded money cannot just disappear -- their
  # entries would be orphaned and every other balance would silently move.
  private def check_for_entries
    return if payout_entries.empty?

    errors.add(:base, :has_entries)
    throw :abort
  end
end
