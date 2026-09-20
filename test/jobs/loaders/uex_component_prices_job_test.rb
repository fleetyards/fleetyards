# frozen_string_literal: true

require "test_helper"

module Loaders
  class UexComponentPricesJobTest < ActiveJob::TestCase
    test "#perform syncs and records what it wrote" do
      stub_run

      GithubIssueCreator.expects(:new).never

      ::Loaders::UexComponentPricesJob.new.perform

      import = Imports::UexComponentPricesImport.last

      assert_equal "finished", import.aasm_state
      assert_equal(
        {
          "created" => 4, "updated" => 1, "removed" => 2, "skipped_removals" => 0,
          "unknown" => [], "ambiguous" => []
        },
        import.output
      )
    end

    # A UEX item no component is named by is mostly personal gear -- clothing,
    # food, FPS weapons -- that this catalogue does not carry and never will, so
    # it is recorded but does not raise an issue for somebody to act on.
    test "#perform records an unplaceable item without opening an issue" do
      stub_run(unknown: [{"id_item" => 14, "item_name" => "Lillo Pants Violet"}])

      GithubIssueCreator.expects(:new).never

      ::Loaders::UexComponentPricesJob.new.perform

      assert_equal ["Lillo Pants Violet"], Imports::UexComponentPricesImport.last.output["unknown"]
    end

    # A name several components answer to is the one that needs a person: only a
    # MAPPINGS entry can say which mount the shop actually stocks.
    test "#perform opens an issue for a name several components answer to" do
      stub_run(ambiguous: [[{"id_item" => 12, "item_name" => "VariPuck S3 Gimbal Mount"}, %w[mount_gimbal_s3 mount_gimbal_s3_polaris]]])

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "uex_component_prices_import",
        report_key: "uex_component_prices",
        title: "UEX Component Sync — Items We Cannot Place",
        body: anything
      ).returns(creator)

      ::Loaders::UexComponentPricesJob.new.perform

      assert_equal ["VariPuck S3 Gimbal Mount -> mount_gimbal_s3, mount_gimbal_s3_polaris"],
        Imports::UexComponentPricesImport.last.output["ambiguous"]
    end

    test "#perform fails the import and re-raises when the sync raises" do
      syncer = mock("Uex::ComponentPriceSyncer")
      syncer.expects(:run).raises(::Uex::Error, "UEX returned no usable rows for item_prices")
      ::Uex::ComponentPriceSyncer.stubs(:new).returns(syncer)

      assert_raises(::Uex::Error) { ::Loaders::UexComponentPricesJob.new.perform }

      import = Imports::UexComponentPricesImport.last

      assert_equal "failed", import.aasm_state
      assert_equal "UEX returned no usable rows for item_prices", import.info
    end

    private def stub_run(unknown: [], ambiguous: [])
      syncer = mock("Uex::ComponentPriceSyncer")
      syncer.stubs(:run).returns(sync_result(unknown:, ambiguous:))
      ::Uex::ComponentPriceSyncer.stubs(:new).returns(syncer)
    end

    private def sync_result(unknown:, ambiguous:)
      ::Uex::ComponentPriceSyncer::Result.new(
        created: 4, updated: 1, removed: 2, skipped_removals: 0,
        unknown:, ambiguous:
      )
    end
  end
end
