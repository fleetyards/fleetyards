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

    private def link(actor:, source:, destination: nil, recipient: nil)
      TransferLink.new(contract: @contract, actor: actor, source: source,
        destination: destination, recipient: recipient)
    end
  end
end
