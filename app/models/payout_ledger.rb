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

  # Order matters. Rails runs dependent callbacks in declaration order, and both
  # entries and transfers hold a FK to a participant -- transfers at the
  # database level, entries additionally through the before_destroy guard that
  # refuses while a participant still has any. Destroying participants first
  # therefore raises InvalidForeignKey and leaves the ledger undeletable.
  has_many :payout_transfers, dependent: :delete_all
  has_many :payout_entries, dependent: :delete_all
  has_many :payout_participants, dependent: :delete_all

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
      # Taken before anything is read. PayoutEntry#ledger_is_open takes the same
      # lock, so an entry racing this either lands before the snapshot or finds
      # the ledger already settled -- rather than committing money into a payout
      # list that was computed without it and can no longer be edited.
      lock!

      payout_transfers.delete_all

      settlement.transfers.each do |transfer|
        payout_transfers.create!(
          from_participant_id: transfer.from_participant.id,
          to_participant_id: transfer.to_participant.id,
          amount: transfer.amount
        )
      end

      update!(status: "settled", settled_at: Time.current, settled_by: user)

      carry_status_to_subject(:settle)
    end
  end

  def reopen!
    transaction do
      lock!

      payout_transfers.delete_all
      update!(status: "open", settled_at: nil, settled_by: nil)

      carry_status_to_subject(:reopen)
    end
  end

  # A tour has a status of its own, and its page is what people read to know
  # whether the money is settled. Two endpoints reach this ledger -- the tour's
  # and the ledger's own, which is the one the UI actually calls -- so the
  # transition is carried here rather than in either controller, or the two
  # paths disagree about whether the tour is settled.
  #
  # A fleet event has its own lifecycle that means something else entirely, so
  # only a tour follows.
  private def carry_status_to_subject(event)
    return unless subject.is_a?(Tour)
    return unless subject.public_send(:"may_#{event}?")

    subject.public_send(:"#{event}!")
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
      # Confirmed only. "interested" and "tentative" are expressions of maybe,
      # and "pending" is still awaiting approval -- seeding those would divide
      # the take among people who never turned up, and an event with four
      # attendees and thirty maybes would default to a thirty-four way split.
      subject.fleet_event_signups
        .where(status: "confirmed")
        .includes(:fleet_membership)
        .filter_map { |signup| signup.fleet_membership&.user_id }
    when Tour
      [subject.created_by_id]
    else
      []
    end
  end
end
