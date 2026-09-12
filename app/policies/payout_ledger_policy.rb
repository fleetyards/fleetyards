# frozen_string_literal: true

# The one place a ledger's two owners are allowed to differ.
#
# A ledger on a fleet event answers to the fleet's roles, the event's creator
# and its per-event admins. A ledger on a standalone tour has none of that, so
# it answers to its own participant list: anyone on the tour can read it and
# record what they spent, and only the organiser manages the list or settles it.
#
# Every rule below routes through `read?` / `contribute?` / `manage?`, and only
# those three branch on the subject. Anything that needs a fourth shape wants
# two policies and a shared concern instead of another branch here.
class PayoutLedgerPolicy < FleetBasePolicy
  authorize :payout_ledger, optional: true

  def show? = read?

  def index? = read?

  def balances? = read?

  # Opening a ledger is structural, not a contribution: it decides that this
  # event settles money at all, and seeds the participant list everyone's share
  # is divided by. `fleet:payouts:create` is the privilege for recording an
  # entry -- see `contribute?` -- and deliberately does not reach this.
  def create? = manage?

  def update? = manage?

  def destroy? = manage?

  def settle? = manage?

  alias_rule :reopen?, to: :settle?

  def manage?
    return false if ledger.blank?

    case subject
    when FleetEvent
      accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:payouts:manage"]) ||
        subject.event_moderator_or_admin?(user)
    when Tour
      tour_organiser?
    else
      false
    end
  end

  # Whether the signed-in user may record money against this ledger at all. The
  # entry and participant policies both start here.
  def contribute?
    return false if ledger.blank?
    return false unless ledger.open?
    return true if manage?

    case subject
    when FleetEvent
      accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:payouts:manage", "fleet:payouts:create"]) &&
        participant?
    when Tour
      participant?
    else
      false
    end
  end

  def read?
    return false if ledger.blank?

    case subject
    when FleetEvent
      accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:payouts:manage", "fleet:payouts:read"])
    when Tour
      participant? || tour_organiser?
    else
      false
    end
  end

  params_filter do |params|
    params.permit(:notes)
  end

  private def ledger
    @ledger ||= record.is_a?(PayoutLedger) ? record : payout_ledger
  end

  private def subject
    ledger&.subject
  end

  private def participant?
    return false if user.blank? || ledger.blank?

    ledger.payout_participants.exists?(user_id: user.id)
  end

  private def tour_organiser?
    subject.is_a?(Tour) && user.present? && subject.created_by_id == user.id
  end

  # FleetBasePolicy resolves a membership from `record.fleet_id`, which a
  # ledger does not have -- its fleet is two hops away, through the subject.
  private def fleet_membership
    fleet_id = subject.is_a?(FleetEvent) ? subject.fleet_id : fleet&.id
    return if fleet_id.blank?

    user&.fleet_memberships&.kept&.find_by(fleet_id: fleet_id)
  end
end
