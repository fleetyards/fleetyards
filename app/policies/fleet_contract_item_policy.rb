# frozen_string_literal: true

# What a contract asks for is part of the contract, so editing a line costs
# what editing the contract costs. Delegated through the contract rather than
# re-derived, so the two can never disagree.
class FleetContractItemPolicy < FleetBasePolicy
  authorize :fleet_contract, optional: true

  def create?
    contract_policy.update?
  end

  alias_rule :update?, :destroy?, to: :create?

  params_filter do |params|
    params.permit(:name, :category, :unit, :quantity, :min_quality, :item_type, :item_id, :position)
  end

  private def contract
    record.try(:fleet_contract) || fleet_contract
  end

  private def contract_policy
    ::FleetContractPolicy.new(contract, user: user)
  end
end
