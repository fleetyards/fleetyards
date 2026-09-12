# frozen_string_literal: true

# == Schema Information
#
# Table name: payout_entries
#
#  id                    :uuid             not null, primary key
#  amount                :decimal(15, 2)   not null
#  description           :string           not null
#  entry_type            :integer          default(0), not null
#  notes                 :text
#  occurred_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  payout_ledger_id      :uuid             not null
#  payout_participant_id :uuid             not null
#  recorded_by_id        :uuid
#
# Indexes
#
#  index_payout_entries_on_payout_ledger_id                 (payout_ledger_id)
#  index_payout_entries_on_payout_ledger_id_and_entry_type  (payout_ledger_id,entry_type)
#  index_payout_entries_on_payout_participant_id            (payout_participant_id)
#
# Foreign Keys
#
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (payout_participant_id => payout_participants.id)
#  fk_rails_...  (recorded_by_id => users.id)
#
class PayoutEntry < ApplicationRecord
  ENTRY_TYPES = {expense: 0, income: 1}.freeze

  paginates_per 50

  belongs_to :payout_ledger, touch: true
  belongs_to :payout_participant
  belongs_to :recorded_by, class_name: "User", optional: true

  enum :entry_type, ENTRY_TYPES

  # Direction lives in entry_type, so the amount is always what was actually
  # handed over. The same split InventoryLedgerEntry makes between deposit and
  # withdrawal.
  validates :amount, numericality: {greater_than: 0}
  validates :description, presence: true
  validate :participant_belongs_to_ledger
  validate :ledger_is_open

  DEFAULT_SORTING_PARAMS = ["createdAt desc"]
  ALLOWED_SORTING_PARAMS = [
    "amount asc", "amount desc",
    "entryType asc", "entryType desc",
    "occurredAt asc", "occurredAt desc",
    "createdAt asc", "createdAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[payout_ledger_id payout_participant_id entry_type amount description occurred_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[payout_ledger payout_participant recorded_by]
  end

  private def participant_belongs_to_ledger
    return if payout_participant.blank? || payout_ledger_id.blank?
    return if payout_participant.payout_ledger_id == payout_ledger_id

    errors.add(:payout_participant_id, :wrong_ledger)
  end

  # A settled ledger has transfers people are paying against. Letting an entry
  # move underneath them would leave the frozen list describing a split that no
  # longer exists.
  private def ledger_is_open
    return if payout_ledger.blank?

    # Locked before the status is read, the same way
    # InventoryLedgerEntry#withdrawal_does_not_exceed_stock locks its inventory:
    # without it this check and PayoutLedger#settle! can both pass on the same
    # ledger, and the entry lands after the transfers were frozen.
    payout_ledger.lock! if payout_ledger.persisted?

    return if payout_ledger.open?

    errors.add(:base, :ledger_settled)
  end
end
