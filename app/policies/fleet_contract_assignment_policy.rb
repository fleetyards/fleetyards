# frozen_string_literal: true

# Joining a crew, and answering the people who asked.
class FleetContractAssignmentPolicy < FleetBasePolicy
  authorize :fleet_contract, optional: true

  def index?
    contract_policy.index?
  end

  # Asking to join needs no more than being able to see the board. The lead
  # decides, not the privilege system.
  def create?
    return false unless contract_policy.index?
    return false unless contract.in_progress?

    contract.accepting_crew?
  end

  # The lead answers for their own contract; a manager can too, because a lead
  # who has gone quiet would otherwise leave every request unanswerable.
  def answer?
    contract.lead?(user) || contract_policy.manage?
  end

  alias_rule :accept?, :decline?, to: :answer?

  # Leaving is yours to do; taking somebody else off is the lead's or a
  # manager's.
  def destroy?
    return true if record.user_id == user&.id

    answer?
  end

  private def contract
    record.try(:fleet_contract) || fleet_contract
  end

  private def contract_policy
    ::FleetContractPolicy.new(contract, user: user)
  end
end
