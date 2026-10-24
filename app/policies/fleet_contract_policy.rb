# frozen_string_literal: true

class FleetContractPolicy < FleetBasePolicy
  READ = ["fleet:manage", "fleet:contracts:manage", "fleet:contracts:read"].freeze
  MANAGE = ["fleet:manage", "fleet:contracts:manage"].freeze
  WRITE = ["fleet:manage", "fleet:contracts:manage", "fleet:contracts:create", "fleet:contracts:update"].freeze

  def index?
    accepted_fleet_membership&.has_access?(READ)
  end

  # A draft is not a job offer yet, so it is only visible to the people who
  # could publish it. Without this the board would advertise work nobody has
  # agreed to pay for.
  def show?
    return false unless index?
    return false unless reachable_by_squadron?
    return true unless record.try(:draft?)

    manage? || own_personal_contract?
  end

  # A contract raised for a squadron is on the board for that squadron. Whoever
  # may run the fleet's contracts reaches all of them, which is the same
  # exception the draft rule above makes.
  private def reachable_by_squadron?
    return true if record.blank? || manage?

    record.visible_to_squadrons_of?(accepted_fleet_membership)
  end

  # A personal contract delivers into the author's own inventory and is paid by
  # them, so posting one takes no more than reading the board -- as long as the
  # fleet has not switched them off.
  def create?
    return true if accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:contracts:manage",
      "fleet:contracts:create"])
    return false unless index? && ::FleetContract.personal_open_to?(contract_fleet, user)
    return true unless record.is_a?(::FleetContract)

    record.personal?
  end

  # Posting work the fleet pays for and that lands in its inventories, as
  # opposed to a member's personal contract.
  def write_fleet_contracts?
    accepted_fleet_membership&.has_access?(WRITE)
  end

  # Only a draft. Published, it is an offer members have read and may already be
  # working to, so the terms stop moving -- what it pays and what it asks for
  # are what somebody claimed it on. Cancelling is the way out, and that is its
  # own rule.
  def update?
    return false unless may_update? || own_personal_contract?

    record.blank? || record.draft?
  end

  # The author of a personal contract may throw away a draft nobody has seen.
  def destroy?
    return true if accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:contracts:manage",
      "fleet:contracts:delete"])

    own_personal_contract? && record.draft?
  end

  # Publishing is what ends the editable phase, so it is the one thing a draft
  # is for. Cancelling has to reach a contract that is already out there, which
  # `update?` deliberately no longer does.
  def publish?
    (may_update? || own_personal_contract?) && record.draft?
  end

  def cancel?
    may_update? || own_personal_contract?
  end

  private def may_update?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:contracts:manage",
      "fleet:contracts:update"])
  end

  # Still the author's to run when the fleet later switches personal contracts
  # off: that stops new ones, it does not take the existing ones away.
  private def own_personal_contract?
    return false unless record.is_a?(::FleetContract) && record.personal?
    return false if user.blank? || record.created_by_id != user.id

    index?
  end

  private def contract_fleet
    case record
    when ::FleetContract then record.fleet
    when ::Fleet then record
    else fleet
    end
  end

  def manage?
    accepted_fleet_membership&.has_access?(MANAGE)
  end

  # Asking where a contract can deliver is part of writing one, so it is open to
  # whoever may create or edit contracts.
  def choose_destination?
    create? || may_update?
  end

  # Claiming rides on read -- of this contract, so a squadron's work is taken
  # by that squadron. A board only officers may take work off is not a board,
  # and the claim itself grants nothing beyond the transfers the member could
  # already make.
  def claim?
    return false unless show?

    record.open?
  end

  # The lead gives it up; a manager can also take it off someone who has gone
  # quiet.
  def release?
    return false unless record.in_progress?

    record.lead?(user) || manage?
  end

  # Forcing a fulfilment early is a manager's call -- it is what makes a
  # part-delivered or renegotiated job payable at all. An expired contract that
  # was part-delivered is the same case, so it may be forced as well.
  def fulfil?
    manage? && (record.in_progress? || record.expired?)
  end

  alias_rule :progress?, to: :show?

  # `items` is the create form's nested list: a contract and the goods it asks
  # for arrive together, because a contract with nothing to deliver cannot be
  # published and making the author save one to get a second form is the long
  # way round.
  params_filter do |params|
    params.permit(:title, :description, :kind, :reward, :reimburse_expenses,
      :crew_limit, :deadline, :cover_image, :cover_image_preset,
      :source_fleet_inventory_id, :destination_fleet_inventory_id, :destination_inventory_id,
      :visibility, fleet_squadron_ids: [],
      items: [:name, :category, :unit, :quantity, :quality, :quality_match, :item_type,
        :item_id, :position, :crafted_blueprint_id, {crafted_qualities: {}}])
  end
end
