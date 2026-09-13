# frozen_string_literal: true

class FleetContractPolicy < FleetBasePolicy
  READ = ["fleet:manage", "fleet:contracts:manage", "fleet:contracts:read"].freeze
  MANAGE = ["fleet:manage", "fleet:contracts:manage"].freeze

  def index?
    accepted_fleet_membership&.has_access?(READ)
  end

  # A draft is not a job offer yet, so it is only visible to the people who
  # could publish it. Without this the board would advertise work nobody has
  # agreed to pay for.
  def show?
    return false unless index?
    return true unless record.try(:draft?)

    manage?
  end

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:contracts:manage", "fleet:contracts:create"])
  end

  def update?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:contracts:manage", "fleet:contracts:update"])
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:contracts:manage", "fleet:contracts:delete"])
  end

  alias_rule :publish?, :cancel?, to: :update?

  def manage?
    accepted_fleet_membership&.has_access?(MANAGE)
  end

  # Claiming rides on read. A board only officers may take work off is not a
  # board, and the claim itself grants nothing beyond the transfers the member
  # could already make.
  def claim?
    return false unless index?

    record.open?
  end

  # The lead gives it up; a manager can also take it off someone who has gone
  # quiet.
  def release?
    return false unless record.in_progress?

    record.lead?(user) || manage?
  end

  # Forcing a fulfilment early is a manager's call -- it is what makes a
  # part-delivered or renegotiated job payable at all.
  def fulfil?
    manage? && record.in_progress?
  end

  alias_rule :progress?, to: :show?

  params_filter do |params|
    params.permit(:title, :description, :kind, :reward, :reimburse_expenses,
      :crew_limit, :deadline, :source_fleet_inventory_id, :destination_fleet_inventory_id)
  end
end
