# frozen_string_literal: true

require "test_helper"

module Loaders
  class UexEquipmentPricesJobTest < ActiveJob::TestCase
    test "#perform syncs and records what it wrote" do
      stub_run

      GithubIssueCreator.expects(:new).never

      ::Loaders::UexEquipmentPricesJob.new.perform

      import = Imports::UexEquipmentPricesImport.last

      assert_equal "finished", import.aasm_state
      assert_equal(
        {
          "created" => 4, "updated" => 1, "removed" => 2, "skipped_removals" => 0,
          "unknown" => [], "unknown_other" => 0, "ambiguous" => [], "stale_mappings" => []
        },
        import.output
      )
    end

    test "#perform counts a priced item outside every gear section without opening an issue" do
      stub_run(unknown_other: [{"id_item" => 24, "item_name" => "Big Benny's Noodles"}])

      GithubIssueCreator.expects(:new).never

      ::Loaders::UexEquipmentPricesJob.new.perform

      assert_equal 1, Imports::UexEquipmentPricesImport.last.output["unknown_other"]
    end

    test "#perform opens an issue for gear it cannot place" do
      stub_run(unknown: [{"id_item" => 23, "item_name" => "Ghostwalker Core"}])
      expect_issue

      ::Loaders::UexEquipmentPricesJob.new.perform

      assert_equal ["Ghostwalker Core"], Imports::UexEquipmentPricesImport.last.output["unknown"]
    end

    test "#perform opens an issue for a name several items answer to" do
      stub_run(ambiguous: [[{"id_item" => 21, "item_name" => "Beacon Undersuit"}, %w[beacon_undersuit_01 beacon_undersuit_01_02]]])
      expect_issue

      ::Loaders::UexEquipmentPricesJob.new.perform

      assert_equal ["Beacon Undersuit -> beacon_undersuit_01, beacon_undersuit_01_02"],
        Imports::UexEquipmentPricesImport.last.output["ambiguous"]
    end

    test "#perform opens an issue for a mapping that resolves to nothing" do
      stub_run(stale_mappings: [[{"id_item" => 99, "item_name" => "ORC-mkX Core"}, "orc_mkx_core_01"]])
      expect_issue

      ::Loaders::UexEquipmentPricesJob.new.perform

      assert_equal ["ORC-mkX Core -> orc_mkx_core_01"],
        Imports::UexEquipmentPricesImport.last.output["stale_mappings"]
    end

    test "#perform puts the sync counts in the notification of a clean run" do
      create(:admin_user, :super_admin)
      stub_run(unknown_other: [{"id_item" => 14, "item_name" => "Lillo Pants Violet"}])

      ::Loaders::UexEquipmentPricesJob.new.perform

      body = AdminNotification.where(notification_type: "uex_equipment_prices_import").last.body

      assert_match "4 created, 1 updated, 2 removed", body
      assert_match "**Priced outside our sections**: 1, ignored", body
      assert_match "Every priced UEX item in our sections resolved to one we carry.", body
    end

    test "#perform fails the import and re-raises when the sync raises" do
      syncer = mock("Uex::EquipmentPriceSyncer")
      syncer.expects(:run).raises(::Uex::Error, "UEX returned no usable rows for item_prices")
      ::Uex::EquipmentPriceSyncer.stubs(:new).returns(syncer)

      assert_raises(::Uex::Error) { ::Loaders::UexEquipmentPricesJob.new.perform }

      import = Imports::UexEquipmentPricesImport.last

      assert_equal "failed", import.aasm_state
      assert_equal "UEX returned no usable rows for item_prices", import.info
    end

    private def expect_issue
      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "uex_equipment_prices_import",
        report_key: "uex_equipment_prices",
        title: "UEX Equipment Sync — Items We Cannot Place",
        body: anything
      ).returns(creator)
    end

    private def stub_run(unknown: [], unknown_other: [], ambiguous: [], stale_mappings: [])
      syncer = mock("Uex::EquipmentPriceSyncer")
      syncer.stubs(:run).returns(
        ::Uex::EquipmentPriceSyncer::Result.new(
          created: 4, updated: 1, removed: 2, skipped_removals: 0,
          unknown:, unknown_other:, ambiguous:, stale_mappings:
        )
      )
      ::Uex::EquipmentPriceSyncer.stubs(:new).returns(syncer)
    end
  end
end
