# frozen_string_literal: true

require "test_helper"

# A squadron-only contract is reached through its slug by every endpoint that
# hangs off it, so each of those rules has to ask the squadron question and not
# only the fleet-wide read one.
class FleetContractPolicyTest < ActiveSupport::TestCase
  setup do
    @insider = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, members: [@insider, @outsider])

    @squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.find_by!(user: @insider))
  end

  def restricted(*traits)
    create(:fleet_contract, *traits, fleet: @fleet, visibility: :squadron_only, fleet_squadrons: [@squadron])
  end

  def contract_policy(reader, contract)
    FleetContractPolicy.new(contract, user: reader, fleet: @fleet)
  end

  def crew_policy(reader, contract)
    FleetContractAssignmentPolicy.new(nil, user: reader, fleet: @fleet, fleet_contract: contract)
  end

  test "an open squadron contract is claimed only from inside the squadron" do
    contract = restricted(:published)

    assert contract_policy(@insider, contract).apply(:claim?)
    refute contract_policy(@outsider, contract).apply(:claim?)
  end

  test "a squadron contract's crew is listed and joined only from inside the squadron" do
    contract = restricted(:in_progress)

    assert crew_policy(@insider, contract).apply(:index?)
    assert crew_policy(@insider, contract).apply(:create?)
    refute crew_policy(@outsider, contract).apply(:index?)
    refute crew_policy(@outsider, contract).apply(:create?)
  end

  test "a contract for the whole fleet is claimed by anyone who reads the board" do
    contract = create(:fleet_contract, :published, fleet: @fleet)

    assert contract_policy(@outsider, contract).apply(:claim?)
  end
end
