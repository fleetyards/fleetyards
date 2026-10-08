# frozen_string_literal: true

class PayoutTransfer < ApplicationRecord
  belongs_to :payout_ledger, touch: true
  belongs_to :from_participant, class_name: "PayoutParticipant"
  belongs_to :to_participant, class_name: "PayoutParticipant"
  belongs_to :confirmed_by, class_name: "User", optional: true

  validates :amount, numericality: {greater_than: 0}
  validate :participants_differ

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :outstanding, -> { where(confirmed_at: nil) }

  # Updates only -- confirming and unconfirming a payment. The rows themselves
  # are created and deleted by PayoutLedger#settle!, whose own status broadcast
  # already covers that; broadcasting here too would send one message per
  # transfer on every settle.
  after_commit :broadcast_ledger_change, on: :update

  def confirmed? = confirmed_at.present?

  def confirm!(user = nil)
    update!(confirmed_at: Time.current, confirmed_by: user)
  end

  def unconfirm!
    update!(confirmed_at: nil, confirmed_by: nil)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[payout_ledger_id from_participant_id to_participant_id amount confirmed_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[payout_ledger from_participant to_participant]
  end

  private def participants_differ
    return if from_participant_id.blank? || to_participant_id.blank?
    return if from_participant_id != to_participant_id

    errors.add(:to_participant_id, :same_as_sender)
  end

  private def broadcast_ledger_change
    payout_ledger&.broadcast_change
  end
end
