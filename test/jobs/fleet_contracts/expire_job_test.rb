# frozen_string_literal: true

require "test_helper"

module FleetContracts
  class ExpireJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
    end

    test "an open contract past its deadline expires" do
      contract = create(:fleet_contract, :published, fleet: @fleet, deadline: 1.hour.ago)

      ExpireJob.new.perform

      assert contract.reload.expired?
      assert_not_nil contract.expired_at
    end

    test "a contract being worked past its deadline expires" do
      contract = create(:fleet_contract, :in_progress, fleet: @fleet, deadline: 1.hour.ago)

      ExpireJob.new.perform

      assert contract.reload.expired?
    end

    test "a contract whose deadline is still ahead is left alone" do
      contract = create(:fleet_contract, :in_progress, fleet: @fleet, deadline: 1.hour.from_now)

      ExpireJob.new.perform

      assert contract.reload.in_progress?
      assert_nil contract.expired_at
    end

    test "a contract without a deadline never expires" do
      contract = create(:fleet_contract, :published, fleet: @fleet, deadline: nil)

      ExpireJob.new.perform

      assert contract.reload.open?
    end

    test "drafts and closed contracts keep their state" do
      draft = create(:fleet_contract, fleet: @fleet, deadline: 1.hour.ago)
      fulfilled = create(:fleet_contract, :in_progress, fleet: @fleet, deadline: 1.hour.ago)
      fulfilled.update_columns(aasm_state: "fulfilled")

      ExpireJob.new.perform

      assert draft.reload.draft?
      assert fulfilled.reload.fulfilled?
    end

    test "a deadline moved out after the sweep read the contract is honoured" do
      contract = create(:fleet_contract, :published, fleet: @fleet, deadline: 1.hour.ago)
      stale = ::FleetContract.find(contract.id)
      contract.update!(deadline: 1.day.from_now)

      ExpireJob.new.send(:expire, stale)

      assert contract.reload.open?
    end

    test "a contract closed after the sweep read it is not reopened as expired" do
      contract = create(:fleet_contract, :in_progress, fleet: @fleet, deadline: 1.hour.ago)
      stale = ::FleetContract.find(contract.id)
      contract.cancel!

      ExpireJob.new.send(:expire, stale)

      assert contract.reload.cancelled?
      assert_nil contract.expired_at
    end

    test "a contract that no longer validates still expires" do
      contract = create(:fleet_contract, :published, fleet: @fleet, deadline: 1.hour.ago)
      contract.update_columns(destination_fleet_inventory_id: nil)

      ExpireJob.new.perform

      assert contract.reload.expired?
    end

    test "one contract failing does not stop the sweep" do
      first = create(:fleet_contract, :published, fleet: @fleet, deadline: 2.hours.ago)
      second = create(:fleet_contract, :published, fleet: @fleet, deadline: 1.hour.ago)

      job = ExpireJob.new
      failing_id = first.id
      job.define_singleton_method(:expire) do |contract|
        raise ActiveRecord::StatementInvalid, "boom" if contract.id == failing_id

        super(contract)
      end

      Appsignal.expects(:report_error).once
      job.perform

      assert first.reload.open?
      assert second.reload.expired?
    end

    # Expiring a contract moves no goods, the same as cancelling one: a
    # delivery still in flight stays pending, and its own expiry sends the goods
    # home.
    test "an in-flight delivery still compensates back into its source" do
      contractor = create(:user)
      contract = contract_worked_by(contractor, deadline: 1.hour.ago)
      source = create(:inventory, holder: contractor)
      entry = create(:inventory_item, inventory: source, name: "Quantanium",
        category: :commodity, unit: :scu, quantity: 96)

      builder = ::Inventories::TransferBuilder.new(
        source: source, actor: contractor, recipient: @fleet, contract: contract,
        lines: [{position_id: entry.position_id, quantity: 40}]
      )

      assert builder.call, builder.errors.full_messages.to_sentence
      assert builder.transfer.pending?
      assert_equal 56, net(source, "Quantanium")

      ExpireJob.new.perform

      assert contract.reload.expired?
      assert builder.transfer.reload.pending?

      builder.transfer.update!(expires_at: 1.minute.ago)
      ::Inventories::ExpireTransfersJob.new.perform

      assert builder.transfer.reload.expired?
      assert_equal 96, net(source, "Quantanium")
      assert_equal 0.to_d, contract.progress.lines.first.delivered
    end

    private def contract_worked_by(worker, deadline:)
      @fleet = create(:fleet, admins: [worker])
      Flipper.enable("fleet_contracts")
      Flipper.enable("fleet_logistics")
      Flipper.enable_actor(:inventory_transfers, worker)
      Flipper.enable_actor(:inventory_transfers, @fleet)

      depot = create(:fleet_inventory, fleet: @fleet)
      contract = create(:fleet_contract, :in_progress, fleet: @fleet,
        destination_fleet_inventory: depot, deadline: deadline)
      contract.fleet_contract_items.destroy_all
      create(:fleet_contract_item, fleet_contract: contract,
        name: "Quantanium", category: :commodity, unit: :scu, quantity: 800)
      contract.fleet_contract_assignments.create!(user: worker, role: :lead,
        aasm_state: "accepted", accepted_at: Time.current)

      contract
    end

    private def net(inventory, name)
      inventory.reload.stock_positions.find { |row| row.name == name }&.net_quantity.to_i
    end
  end
end
