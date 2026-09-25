# frozen_string_literal: true

# == Schema Information
#
# Table name: payout_entries
#
#  id                    :uuid             not null, primary key
#  amount                :decimal(15, 2)   not null
#  decline_reason        :text
#  description           :string           not null
#  entry_type            :integer          default("expense"), not null
#  notes                 :text
#  occurred_at           :datetime
#  review_status         :integer          default("approved"), not null
#  reviewed_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  payout_ledger_id      :uuid             not null
#  payout_participant_id :uuid             not null
#  recorded_by_id        :uuid
#  reviewed_by_id        :uuid
#
# Indexes
#
#  index_payout_entries_on_payout_ledger_id_and_entry_type     (payout_ledger_id,entry_type)
#  index_payout_entries_on_payout_ledger_id_and_review_status  (payout_ledger_id,review_status)
#  index_payout_entries_on_payout_participant_id               (payout_participant_id)
#
# Foreign Keys
#
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (payout_participant_id => payout_participants.id)
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (reviewed_by_id => users.id)
#
class PayoutEntry < ApplicationRecord
  ENTRY_TYPES = {expense: 0, income: 1}.freeze

  # An expense is a claim on everyone else's share, so one recorded by someone
  # who does not manage the ledger waits for a manager before it counts. Income
  # is not reviewed: recording money you hold only raises what you owe.
  REVIEW_STATUSES = {pending: 0, approved: 1, declined: 2}.freeze

  paginates_per 50

  belongs_to :payout_ledger, touch: true
  belongs_to :payout_participant
  belongs_to :recorded_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :entry_type, ENTRY_TYPES
  enum :review_status, REVIEW_STATUSES, prefix: :review

  # Direction lives in entry_type, so the amount is always what was actually
  # handed over. The same split InventoryLedgerEntry makes between deposit and
  # withdrawal.
  validates :amount, numericality: {greater_than: 0}
  validates :description, presence: true
  validate :participant_belongs_to_ledger
  validate :ledger_is_open
  validate :expenses_reimbursed

  before_destroy :ledger_must_be_open, prepend: true

  # Every participant's page is showing figures derived from this row, so a
  # change here has to reach all of them, not only the tab that made it.
  after_commit :broadcast_ledger_change
  # Somebody is waiting on the other side of both: a manager has an expense to
  # look at, or a participant has one that will not be paid back.
  after_commit :notify_review_change, on: %i[create update], if: :saved_change_to_review_status?

  DEFAULT_SORTING_PARAMS = ["createdAt desc"]
  ALLOWED_SORTING_PARAMS = [
    "amount asc", "amount desc",
    "entryType asc", "entryType desc",
    "occurredAt asc", "occurredAt desc",
    "createdAt asc", "createdAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[payout_ledger_id payout_participant_id entry_type review_status amount description occurred_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[payout_ledger payout_participant recorded_by reviewed_by]
  end

  # Called before every save the API makes, with whether the person saving it
  # manages the ledger. A manager's own figures need nobody's sign-off; anyone
  # else's expense goes back to pending whenever what it claims changes, so an
  # approved amount cannot be edited upwards after the fact.
  def assign_review_status(by_manager:)
    if income? || by_manager
      return unless new_record? || will_save_change_to_entry_type?

      self.review_status = :approved
    elsif new_record? || claim_changed?
      self.review_status = :pending
      self.reviewed_by = nil
      self.reviewed_at = nil
      self.decline_reason = nil
    end
  end

  def approve!(user)
    update!(review_status: :approved, reviewed_by: user, reviewed_at: Time.current, decline_reason: nil)
  end

  def decline!(user, reason: nil)
    update!(review_status: :declined, reviewed_by: user, reviewed_at: Time.current, decline_reason: reason.presence)
  end

  private def claim_changed?
    will_save_change_to_amount? || will_save_change_to_entry_type? ||
      will_save_change_to_payout_participant_id? || will_save_change_to_description?
  end

  # A contract that said it does not reimburse expenses pays the reward and
  # nothing else, so an expense on its ledger would be a claim it already
  # refused.
  private def expenses_reimbursed
    return unless expense?

    contract = payout_ledger&.subject
    return unless contract.is_a?(FleetContract)
    return if contract.reimburse_expenses?

    errors.add(:entry_type, :not_reimbursed)
  end

  private def participant_belongs_to_ledger
    return if payout_participant.blank? || payout_ledger_id.blank?
    return if payout_participant.payout_ledger_id == payout_ledger_id

    errors.add(:payout_participant_id, :wrong_ledger)
  end

  # A settled ledger has transfers people are paying against. Letting an entry
  # move underneath them would leave the frozen list describing a split that no
  # longer exists.
  # Locked before the status is read, the same way
  # InventoryLedgerEntry#withdrawal_does_not_exceed_stock locks its inventory:
  # without it this check and PayoutLedger#settle! can both pass on the same
  # ledger, and the entry lands after the transfers were frozen.
  private def ledger_is_open
    return if payout_ledger.blank?
    return if payout_ledger.open_for_edits?

    errors.add(:base, :ledger_settled)
  end

  # Validations do not run on destroy, so removing an entry needed its own
  # guard -- otherwise money could leave a ledger whose payout list was already
  # frozen around it.
  private def ledger_must_be_open
    return if payout_ledger.blank?
    return if payout_ledger.open_for_edits?

    errors.add(:base, :ledger_settled)
    throw :abort
  end

  private def notify_review_change
    if review_pending?
      notify_managers_of_pending
    elsif review_declined?
      notify_recorder_of_decline
    end
  end

  private def notify_managers_of_pending
    (payout_ledger.managers - [recorded_by]).each do |manager|
      Notification.notify!(
        user: manager,
        type: :payout_entry_pending_review,
        title: I18n.t("notifications.payout_entry_pending_review.title",
          user: payout_participant.display_name, subject: payout_ledger.subject_title),
        body: description,
        link: payout_ledger.page_link,
        icon: "fa-duotone fa-coins",
        record: payout_ledger.subject
      )
    end
  end

  private def notify_recorder_of_decline
    ([payout_participant.user, recorded_by].compact.uniq - [reviewed_by]).each do |recipient|
      Notification.notify!(
        user: recipient,
        type: :payout_entry_declined,
        title: I18n.t("notifications.payout_entry_declined.title",
          description: description, subject: payout_ledger.subject_title),
        body: decline_reason,
        link: payout_ledger.page_link,
        icon: "fa-duotone fa-coins",
        record: payout_ledger.subject
      )
    end
  end

  private def broadcast_ledger_change
    payout_ledger&.broadcast_change
  end
end
