# frozen_string_literal: true

# == Schema Information
#
# Table name: payout_ledgers
#
#  id            :uuid             not null, primary key
#  notes         :text
#  settled_at    :datetime
#  status        :string           default("open"), not null
#  subject_type  :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  settled_by_id :uuid
#  subject_id    :uuid             not null
#
# Indexes
#
#  index_payout_ledgers_on_subject_type_and_subject_id  (subject_type,subject_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (settled_by_id => users.id)
#
class PayoutLedger < ApplicationRecord
  # subject_type reaches us from the client on create, and an unconstrained
  # polymorphic belongs_to would happily point a ledger at any model in the
  # app -- including records the signed-in user cannot see, whose participants
  # would then be seeded onto it. Same reasoning as InventoryLedgerEntry's
  # ITEM_TYPES.
  SUBJECT_TYPES = %w[FleetEvent Tour].freeze

  STATUSES = %w[open settled].freeze

  AVAILABLE_PRIVILEGES = [
    "fleet:payouts:read",
    "fleet:payouts:create",
    "fleet:payouts:update",
    "fleet:payouts:delete",
    "fleet:payouts:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:payouts:manage"],
    member: ["fleet:payouts:read", "fleet:payouts:create"]
  }.freeze

  belongs_to :subject, polymorphic: true, touch: true
  belongs_to :settled_by, class_name: "User", optional: true

  has_many :payout_participants, dependent: :destroy
  has_many :payout_entries, dependent: :destroy
  has_many :payout_transfers, dependent: :destroy

  validates :subject_type, inclusion: {in: SUBJECT_TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :subject_id, uniqueness: {scope: :subject_type}

  def self.ransackable_attributes(_auth_object = nil)
    %w[subject_type subject_id status settled_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[subject payout_participants payout_entries payout_transfers]
  end

  def open? = status == "open"

  def settled? = status == "settled"

  def fleet
    subject.is_a?(FleetEvent) ? subject.fleet : nil
  end

  def settlement
    Payouts::Settlement.new(self)
  end

  # Freezes the computed transfers into rows. While the ledger is open they are
  # derived on every read so they cannot drift from the entries; from here on
  # people pay against this list, so it has to stop moving.
  def settle!(user = nil)
    transaction do
      payout_transfers.delete_all

      settlement.transfers.each do |transfer|
        payout_transfers.create!(
          from_participant_id: transfer.from_participant.id,
          to_participant_id: transfer.to_participant.id,
          amount: transfer.amount
        )
      end

      update!(status: "settled", settled_at: Time.current, settled_by: user)
    end
  end

  def reopen!
    transaction do
      payout_transfers.delete_all
      update!(status: "open", settled_at: nil, settled_by: nil)
    end
  end

  # Seeds the participant list from whoever the subject already knows about.
  # Only ever adds: a participant removed on purpose must not come back the
  # next time this runs.
  def seed_participants_from_subject!
    existing_user_ids = payout_participants.where.not(user_id: nil).pluck(:user_id)

    seed_user_ids_from_subject.uniq.each do |user_id|
      next if existing_user_ids.include?(user_id)

      payout_participants.create!(user_id: user_id)
    end
  end

  private def seed_user_ids_from_subject
    case subject
    when FleetEvent
      subject.fleet_event_signups
        .where.not(status: "withdrawn")
        .includes(:fleet_membership)
        .filter_map { |signup| signup.fleet_membership&.user_id }
    when Tour
      [subject.created_by_id]
    else
      []
    end
  end
end
