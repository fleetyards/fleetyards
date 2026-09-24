# frozen_string_literal: true

require "test_helper"

module Contracts
  class TransferLinkTest < ActiveSupport::TestCase
    setup do
      @lead = create(:user)
      @officer = create(:user)
      @stranger = create(:user)
      @fleet = create(:fleet, admins: [@officer], members: [@lead, @stranger])
      @depot = create(:fleet_inventory, fleet: @fleet)
      @source_depot = create(:fleet_inventory, fleet: @fleet)
      @contract = create(:fleet_contract, :in_progress, :transport, fleet: @fleet,
        source_fleet_inventory: @source_depot, destination_fleet_inventory: @depot)
      create(:fleet_contract_assignment, :lead, fleet_contract: @contract, user: @lead)

      @hold = create(:inventory, holder: @lead)
    end

    test "a contractor delivering into the destination is allowed" do
      assert link(actor: @lead, source: @hold, destination: @depot).call
    end

    test "a contractor collecting from the source is allowed" do
      assert link(actor: @lead, source: @source_depot, recipient: @lead).call
    end

    test "a contractor addressing the fleet is allowed, because the fleet chooses where it lands" do
      assert link(actor: @lead, source: @hold, recipient: @fleet).call
    end

    test "a manager may act even without being on the crew" do
      assert link(actor: @officer, source: @hold, destination: @depot).call
    end

    test "a member who is neither is refused" do
      subject = link(actor: @stranger, source: @hold, destination: @depot)

      assert_not subject.call
      assert_equal :not_a_contractor, subject.error
    end

    test "a contract nobody has taken yet is refused" do
      @contract.update!(aasm_state: "open")
      subject = link(actor: @lead, source: @hold, destination: @depot)

      assert_not subject.call
      assert_equal :contract_not_open, subject.error
    end

    test "a fulfilled contract takes no more deliveries" do
      @contract.update!(aasm_state: "fulfilled")
      subject = link(actor: @lead, source: @hold, destination: @depot)

      assert_not subject.call
      assert_equal :contract_not_open, subject.error
    end

    test "an inventory the contract does not name is refused" do
      elsewhere = create(:fleet_inventory, fleet: @fleet)
      subject = link(actor: @lead, source: @hold, destination: elsewhere)

      assert_not subject.call
      assert_equal :contract_end_not_involved, subject.error
    end

    test "another fleet is not a target for this contract" do
      subject = link(actor: @lead, source: @hold, recipient: create(:fleet))

      assert_not subject.call
      assert_equal :contract_end_not_involved, subject.error
    end

    test "no contract at all is refused rather than treated as unlinked" do
      subject = TransferLink.new(contract: nil, actor: @lead, source: @hold, destination: @depot)

      assert_not subject.call
      assert_equal :contract_not_found, subject.error
    end

    test "a contractor addressing the author of a hangar-destination contract is allowed" do
      contract = hangar_contract

      assert link(actor: @lead, source: @hold, recipient: contract.created_by, contract:).call
    end

    test "the author is not a target of a contract that delivers to the fleet" do
      subject = link(actor: @lead, source: @hold, recipient: @contract.created_by)

      assert_not subject.call
      assert_equal :contract_end_not_involved, subject.error
    end

    # A manager may act on any contract, but addressing a member's private
    # inventory is not dispatching on the fleet's behalf.
    test "a manager off the crew cannot address the author's hangar" do
      contract = hangar_contract
      subject = link(actor: @officer, source: create(:inventory, holder: @officer),
        recipient: contract.created_by, contract:)

      assert_not subject.call
      assert_equal :contract_end_not_involved, subject.error
    end

    test "somebody other than the author is not a target of a hangar-destination contract" do
      subject = link(actor: @lead, source: @hold, recipient: @stranger, contract: hangar_contract)

      assert_not subject.call
      assert_equal :contract_end_not_involved, subject.error
    end

    private def hangar_contract
      author = create(:user)
      create(:fleet_membership, fleet: @fleet, user: author, aasm_state: :accepted,
        fleet_role: @fleet.fleet_roles.ranked.last)
      contract = create(:fleet_contract, :in_progress, :hangar_destination, fleet: @fleet, created_by: author)
      create(:fleet_contract_assignment, :lead, fleet_contract: contract, user: @lead)
      contract
    end

    private def link(actor:, source:, destination: nil, recipient: nil, contract: @contract)
      TransferLink.new(contract: contract, actor: actor, source: source,
        destination: destination, recipient: recipient)
    end
  end
end
