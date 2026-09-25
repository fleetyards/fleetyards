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
  SUBJECT_TYPES = %w[FleetEvent Tour FleetContract].freeze

  STATUSES = %w[open settled].freeze

  # Every fleet privilege some branch of PayoutLedgerPolicy#manage? accepts.
  MANAGER_PRIVILEGES = ["fleet:manage", "fleet:payouts:manage", "fleet:contracts:manage"].freeze

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

  # Only the ledger's own changes. A child touches this row, which commits an
  # update here too, and broadcasting on that as well would send every entry
  # twice -- the children broadcast for themselves.
  after_commit :broadcast_own_change, on: :update

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

  # Settling freezes the transfers, and an expense still waiting for a manager
  # would either be left out of them for good or have to be decided on by
  # whoever happened to press settle.
  def pending_review? = payout_entries.review_pending.exists?

  # Both subjects can carry one: an event always does, a tour only when it was
  # organised from a fleet's page.
  def fleet
    subject.try(:fleet)
  end

  def settlement
    Payouts::Settlement.new(self)
  end

  # Freezes the computed transfers into rows. While the ledger is open they are
  # derived on every read so they cannot drift from the entries; from here on
  # people pay against this list, so it has to stop moving.
  # Returns false rather than raising when the ledger is not in a state to be
  # settled, so the caller can answer 409.
  def settle!(user = nil)
    settled = transaction do
      # Taken before anything is read. Every path that changes a participant or
      # an entry takes the same lock, so one racing this either lands before the
      # snapshot or finds the ledger already settled -- rather than moving money
      # that the frozen payout list was computed without.
      lock!

      # Re-checked after the lock, and not only by the controller: that guard
      # runs outside this transaction, so two simultaneous requests can both
      # pass it and the second would delete and recreate the first's transfers,
      # dropping any confirmation already ticked off against them.
      next false if settled?
      next false if pending_review?

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

      true
    end

    notify_settled(user) if settled

    settled
  end

  def reopen!
    transaction do
      lock!

      next false unless settled?

      payout_transfers.delete_all
      update!(status: "open", settled_at: nil, settled_by: nil)

      carry_status_to_subject(:reopen)

      true
    end
  end

  # Takes the same row lock settle! does, so a caller about to change something
  # the settlement reads either gets in first or sees the settled ledger.
  # Returns false when the ledger is closed for edits.
  def open_for_edits?
    return false if new_record?

    lock!
    open?
  end

  # A tour has a status of its own, and its page is what people read to know
  # whether the money is settled. Two endpoints reach this ledger -- the tour's
  # and the ledger's own, which is the one the UI actually calls -- so the
  # transition is carried here rather than in either controller, or the two
  # paths disagree about whether the tour is settled. A contract's `settled`
  # means the same thing and follows for the same reason.
  #
  # A fleet event has its own lifecycle that means something else entirely, so
  # it does not follow.
  private def carry_status_to_subject(event)
    return unless subject.is_a?(Tour) || subject.is_a?(FleetContract)
    return unless subject.public_send(:"may_#{event}?")

    subject.public_send(:"#{event}!")
  end

  # Seeds the participant list from whoever the subject already knows about.
  # Only ever adds: a participant removed on purpose must not come back the
  # next time this runs.
  def seed_participants_from_subject!
    return seed_contract! if subject.is_a?(FleetContract)

    existing_user_ids = payout_participants.where.not(user_id: nil).pluck(:user_id)

    seed_user_ids_from_subject.uniq.each do |user_id|
      next if existing_user_ids.include?(user_id)

      payout_participants.create!(user_id: user_id)
    end
  end

  # Everyone on the ledger is reading the same numbers, so a change has to reach
  # all of them rather than only whoever made it. Guests have no account to
  # address, which is why this walks the participants' users rather than the
  # participants.
  def broadcast_change
    payload = to_jbuilder_hash

    User.where(id: payout_participants.where.not(user_id: nil).select(:user_id)).find_each do |user|
      PayoutLedgerChannel.broadcast_to(user, payload)
    end
  end

  # For the people a change concerns who are not on the ledger themselves.
  # Somebody who can answer a request to join a tour has no participant row
  # until they join one, so `broadcast_change` would never reach them -- and
  # the request is exactly what they are waiting to see. Every caller passes
  # users who may already read this ledger.
  def broadcast_change_to(users)
    payload = to_jbuilder_hash

    Array(users).compact.uniq.each do |user|
      PayoutLedgerChannel.broadcast_to(user, payload)
    end
  end

  private def broadcast_own_change
    return unless saved_change_to_status? || saved_change_to_notes?

    broadcast_change
  end

  # The fleet is the payer and holds the reward; the contractors are weighted
  # by what they delivered. Only run on create, so it has nothing to preserve.
  # After the commit, so nobody is told about a payout list that rolled back.
  # Whoever pressed settle already knows. A contract's author is the client and
  # is told as well, whether or not they are on the list.
  # Everyone PayoutLedgerPolicy lets manage this ledger. The candidates are
  # narrowed first -- a fleet's privileged members and the people the subject
  # itself hands the ledger to -- and the policy then has the last word, so
  # this cannot drift from who may actually approve an expense.
  def managers
    candidates = []

    if fleet.present?
      candidates += fleet.fleet_memberships.where(aasm_state: "accepted").includes(:user, :fleet_role)
        .select { |membership| membership.has_access?(MANAGER_PRIVILEGES) }
        .filter_map(&:user)
    end

    candidates << subject.try(:created_by)
    candidates += subject.event_admin_users.to_a if subject.is_a?(FleetEvent)

    candidates.compact.uniq.select do |user|
      PayoutLedgerPolicy.new(self, user: user, payout_ledger: self, fleet: fleet).manage?
    end
  end

  # What a notification about this ledger links to and calls it.
  def page_link
    case subject
    when FleetContract then "/fleets/#{subject.fleet.slug}/contracts/#{subject.slug}/payouts/"
    when FleetEvent then "/fleets/#{subject.fleet.slug}/events/#{subject.slug}/payouts/"
    when Tour then subject.fleet ? "/fleets/#{subject.fleet.slug}/tours/#{subject.slug}/" : "/tools/tours/#{subject.slug}/"
    end
  end

  def subject_title
    subject.is_a?(FleetContract) ? subject.display_title : subject.title
  end

  private def notify_settled(settler)
    recipients = User.where(id: payout_participants.where.not(user_id: nil).select(:user_id)).to_a
    recipients << subject.created_by if subject.is_a?(FleetContract)

    recipients.compact.uniq.reject { |recipient| recipient == settler }.each do |recipient|
      Notification.notify!(user: recipient, record: subject, icon: "fa-duotone fa-coins", **settled_notification)
    end
  end

  private def settled_notification
    if subject.is_a?(FleetContract)
      {
        type: :fleet_contract_settled,
        title: I18n.t("notifications.fleet_contract.settled.title", title: subject_title),
        link: "/fleets/#{subject.fleet.slug}/contracts/#{subject.slug}"
      }
    else
      {
        type: :payout_ledger_settled,
        title: I18n.t("notifications.payout_ledger_settled.title", subject: subject_title),
        link: page_link
      }
    end
  end

  private def seed_contract!
    payer = payout_participants.create!(fleet: subject.fleet)

    contract_weights.each do |user_id, weight|
      payout_participants.create!(user_id: user_id, weight: weight)
    end

    return unless subject.reward.positive?

    payout_entries.create!(
      payout_participant: payer,
      entry_type: :income,
      review_status: :approved,
      amount: subject.reward,
      description: I18n.t("fleet_contracts.payout_reward", title: subject.display_title)
    )
  end

  # Contracts::Progress weights are fractions of a line, which a two-decimal
  # column cannot hold for somebody who delivered one crate of eight hundred.
  # Scaled to a percentage of the whole, they keep their proportions and read
  # as what they are. A contract forced to fulfilled with nothing measured
  # divides evenly across whoever was on it.
  private def contract_weights
    weights = subject.progress.weights.select { |_user_id, weight| weight.positive? }
    total = weights.values.sum(0.to_d)

    if total.zero?
      return subject.contractor_assignments.pluck(:user_id).uniq.index_with { 1 }
    end

    weights.transform_values do |weight|
      (weight * 100 / total).round(2).clamp(BigDecimal("0.01"), BigDecimal("999.99"))
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
