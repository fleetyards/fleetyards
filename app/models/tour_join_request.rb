# frozen_string_literal: true

# == Schema Information
#
# Table name: tour_join_requests
#
#  id            :uuid             not null, primary key
#  aasm_state    :string           default("pending"), not null
#  decided_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  decided_by_id :uuid
#  tour_id       :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_tour_join_requests_on_decided_by_id          (decided_by_id)
#  index_tour_join_requests_on_pending_tour_and_user  (tour_id,user_id) UNIQUE WHERE ((aasm_state)::text = 'pending'::text)
#  index_tour_join_requests_on_tour_id                (tour_id)
#  index_tour_join_requests_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (decided_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (tour_id => tours.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class TourJoinRequest < ApplicationRecord
  include AASM

  belongs_to :tour, touch: true
  belongs_to :user
  belongs_to :decided_by, class_name: "User", optional: true

  validate :tour_belongs_to_a_fleet, on: :create
  validate :tour_is_open, on: :create
  validate :not_already_a_participant, on: :create
  validate :no_pending_request, on: :create

  aasm column: :aasm_state, whiny_transitions: false do
    state :pending, initial: true
    state :approved
    state :declined

    event :approve do
      transitions from: :pending, to: :approved
    end

    event :decline do
      transitions from: :pending, to: :declined
    end
  end

  # Approving is what puts somebody on the ledger, so the participant row and
  # the answer are one transaction -- an approved request with nobody on the
  # list would read as "you are on the tour" while dividing nothing to them.
  # Answers false rather than raising when the ledger closed in between, which
  # is the same shape PayoutLedger#settle! uses for the same race.
  def approve_by(decider)
    with_lock do
      return false unless pending?

      ledger = tour.payout_ledger
      return false if ledger.blank?

      participant = ledger.payout_participants.find_or_initialize_by(user_id: user_id)
      return false unless participant.persisted? || participant.save

      assign_attributes(decided_by: decider, decided_at: Time.current)
      approve!
    end
  end

  def decline_by(decider)
    with_lock do
      return false unless pending?

      assign_attributes(decided_by: decider, decided_at: Time.current)
      decline!
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[aasm_state tour_id user_id created_at updated_at decided_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[tour user decided_by]
  end

  private def tour_belongs_to_a_fleet
    return if tour.blank? || tour.fleet_id.present?

    # A standalone tour is not listed anywhere its organiser's fleet can see
    # it, so there is nobody to ask -- the invite link is the only way onto one.
    errors.add(:tour, :standalone)
  end

  private def tour_is_open
    return if tour.blank? || tour.open?

    errors.add(:tour, :not_open)
  end

  private def not_already_a_participant
    return if tour.blank? || user_id.blank?
    return unless tour.payout_ledger&.payout_participants&.exists?(user_id: user_id)

    errors.add(:user, :already_participating)
  end

  # Mirrors the partial unique index, so the second ask is a validation error
  # rather than a RecordNotUnique out of the database.
  private def no_pending_request
    return if tour.blank? || user_id.blank?
    return unless self.class.pending.exists?(tour_id: tour_id, user_id: user_id)

    errors.add(:base, :already_requested)
  end
end
