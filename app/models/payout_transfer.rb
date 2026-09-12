# frozen_string_literal: true

# == Schema Information
#
# Table name: payout_transfers
#
#  id                  :uuid             not null, primary key
#  amount              :decimal(15, 2)   not null
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  confirmed_by_id     :uuid
#  from_participant_id :uuid             not null
#  payout_ledger_id    :uuid             not null
#  to_participant_id   :uuid             not null
#
# Indexes
#
#  index_payout_transfers_on_from_participant_id  (from_participant_id)
#  index_payout_transfers_on_payout_ledger_id     (payout_ledger_id)
#  index_payout_transfers_on_to_participant_id    (to_participant_id)
#
# Foreign Keys
#
#  fk_rails_...  (confirmed_by_id => users.id)
#  fk_rails_...  (from_participant_id => payout_participants.id)
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (to_participant_id => payout_participants.id)
#
class PayoutTransfer < ApplicationRecord
  belongs_to :payout_ledger, touch: true
  belongs_to :from_participant, class_name: "PayoutParticipant"
  belongs_to :to_participant, class_name: "PayoutParticipant"
  belongs_to :confirmed_by, class_name: "User", optional: true

  validates :amount, numericality: {greater_than: 0}
  validate :participants_differ

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :outstanding, -> { where(confirmed_at: nil) }

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
end
