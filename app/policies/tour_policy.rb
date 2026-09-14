# frozen_string_literal: true

# A standalone tour has no fleet and no roles: the organiser created it,
# everyone else is on it because they joined. That is the whole authorization
# model for one.
#
# A tour created from a fleet's page carries that fleet, and then the fleet's
# payout privileges apply on top -- so an officer can find, read and settle a
# tour they never joined, and the trip does not die with whoever organised it.
class TourPolicy < FleetBasePolicy
  READ_PRIVILEGES = ["fleet:manage", "fleet:payouts:manage", "fleet:payouts:read"].freeze
  CREATE_PRIVILEGES = ["fleet:manage", "fleet:payouts:manage", "fleet:payouts:create"].freeze
  MANAGE_PRIVILEGES = ["fleet:manage", "fleet:payouts:manage"].freeze

  # Authorized without a record for the standalone list, and with a fleet in
  # context for a fleet's own list.
  def index?
    return false if user.blank?
    return true if fleet.blank?

    fleet_access?(READ_PRIVILEGES)
  end

  def show?
    organiser? || participant? || fleet_access?(READ_PRIVILEGES)
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

  # Deliberately not widened by fleet privileges: this is the list of tours the
  # signed-in user is on, and an officer's payout privileges would otherwise
  # empty every fleet they can read into their personal tools page. A fleet's
  # own tours are listed by the fleet-scoped index, which authorizes `index?`
  # with that fleet in context.
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
end
