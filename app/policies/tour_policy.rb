# frozen_string_literal: true

# A standalone tour has no fleet and no roles: the organiser created it,
# everyone else is on it because they joined. That is the whole authorization
# model for one.
#
# A tour created from a fleet's page carries that fleet, and then the fleet's
# payout privileges apply on top -- so an officer can settle a tour they never
# joined, and the trip does not die with whoever organised it.
#
# Finding one is not a payout right, though: every member of the fleet reads
# the list and the tour page, which is how they find a trip to ask onto. The
# money stays behind PayoutLedgerPolicy, which still wants a participant row or
# a payout privilege.
class TourPolicy < FleetBasePolicy
  CREATE_PRIVILEGES = ["fleet:manage", "fleet:payouts:manage", "fleet:payouts:create"].freeze
  MANAGE_PRIVILEGES = ["fleet:manage", "fleet:payouts:manage"].freeze

  # Authorized without a record for the standalone list, and with a fleet in
  # context for a fleet's own list.
  def index?
    return false if user.blank?
    return true if fleet.blank?

    fleet_member?
  end

  def show?
    organiser? || participant? || fleet_member?
  end

  def create?
    return false if user.blank?
    return true if scoped_fleet_id.blank?

    fleet_access?(CREATE_PRIVILEGES)
  end

  def update? = organiser? || fleet_access?(MANAGE_PRIVILEGES)

  alias_rule :destroy?, :settle?, :reopen?, :cancel?, :rotate_invite?, to: :update?

  # Anyone with the link may join; the token is the credential.
  def join? = user.present?

  alias_rule :find_by_invite?, to: :join?

  # Every tour the signed-in user is on, fleet-owned ones included. Which of
  # them the personal tools list repeats is the controller's business -- this
  # answers what they are allowed to see, and an officer's payout privileges
  # deliberately do not widen it, or every fleet they can read would empty into
  # their own page.
  relation_scope do |relation|
    next relation.none if user.blank?

    relation
      .left_joins(payout_ledger: :payout_participants)
      .where(
        "tours.created_by_id = :user_id OR payout_participants.user_id = :user_id",
        user_id: user.id
      )
      .distinct
  end

  params_filter do |params|
    params.permit(:title, :description, :starts_at)
  end

  private def organiser?
    user.present? && record.respond_to?(:created_by_id) && record.created_by_id == user.id
  end

  private def participant?
    return false if user.blank? || !record.respond_to?(:payout_ledger)

    record.payout_ledger&.payout_participants&.exists?(user_id: user.id) || false
  end

  # A tour's own fleet, never the one in context: authorizing a standalone tour
  # inside a fleet-scoped request must not borrow that fleet's privileges.
  # FleetBasePolicy resolves the membership from the same two places in the
  # same order, so this only has to decide whether there is a fleet at all.
  private def scoped_fleet_id
    return record.fleet_id if record.is_a?(Tour)

    fleet&.id
  end

  private def fleet_access?(privileges)
    return false if scoped_fleet_id.blank?

    accepted_fleet_membership&.has_access?(privileges) || false
  end

  private def fleet_member?
    return false if scoped_fleet_id.blank?

    accepted_fleet_membership.present?
  end
end
