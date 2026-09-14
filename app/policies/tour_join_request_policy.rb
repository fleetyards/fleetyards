# frozen_string_literal: true

# Who may ask onto a fleet's tour, and who answers.
#
# Asking is a membership right -- the member can already see the tour on their
# fleet's page, and asking is what that page is for. Answering is the same set
# that settles and cancels the tour: its organiser, and the fleet's payout
# managers. Nothing here reaches the ledger; approving does, and that goes
# through TourJoinRequest#approve_by.
class TourJoinRequestPolicy < FleetBasePolicy
  authorize :tour, optional: true

  MANAGE_PRIVILEGES = TourPolicy::MANAGE_PRIVILEGES

  def index? = decider?

  def create?
    return false if user.blank?
    return false if target_tour.blank? || target_tour.fleet_id.blank?

    accepted_fleet_membership.present?
  end

  def approve?
    return false unless record.try(:pending?)

    decider?
  end

  alias_rule :decline?, to: :approve?

  # Withdrawing an ask, which is the requester's own to do. A decider may also
  # clear one off the list without answering it either way.
  def destroy?
    return false unless record.try(:pending?)

    requester? || decider?
  end

  private def requester? = user.present? && record.try(:user_id) == user.id

  private def decider?
    return false if user.blank? || target_tour.blank?
    return true if target_tour.created_by_id == user.id

    accepted_fleet_membership&.has_access?(MANAGE_PRIVILEGES) || false
  end

  private def target_tour
    return @target_tour if defined?(@target_tour)

    @target_tour = record.try(:tour) || (record.is_a?(Tour) ? record : tour)
  end

  # FleetBasePolicy resolves a membership from `record.fleet_id`, which a join
  # request does not have -- its fleet is one hop away, through the tour.
  private def fleet_membership
    fleet_id = target_tour&.fleet_id
    return if fleet_id.blank?

    user&.fleet_memberships&.kept&.find_by(fleet_id: fleet_id)
  end
end
