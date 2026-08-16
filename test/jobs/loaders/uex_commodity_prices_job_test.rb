# frozen_string_literal: true

require "test_helper"

module Loaders
  class UexCommodityPricesJobTest < ActiveJob::TestCase
    test "#perform maps then syncs and records both sets of counts" do
      stub_run(unmapped: [], unknown: [])

      GithubIssueCreator.expects(:new).never

      ::Loaders::UexCommodityPricesJob.new.perform

      import = Imports::UexCommodityPricesImport.last

      assert_equal "finished", import.aasm_state
      assert_equal(
        {
          "mapped" => 7, "remapped" => 2, "unmapped" => [],
          "created" => 4, "updated" => 1, "removed" => 2, "skipped_removals" => 0, "unknown" => []
        },
        import.output
      )
    end

    # The mapper has to land first: a commodity the last game-file import added
    # carries no uex_id yet, and the syncer would drop its prices as unknown.
    test "#perform maps before it syncs" do
      sequence = sequence("mapping before pricing")

      mapper = mock("Uex::CommodityMapper")
      mapper.expects(:run).in_sequence(sequence).returns(mapping_result(unmapped: []))
      ::Uex::CommodityMapper.stubs(:new).returns(mapper)

      syncer = mock("Uex::CommodityPriceSyncer")
      syncer.expects(:run).in_sequence(sequence).returns(sync_result(unknown: []))
      ::Uex::CommodityPriceSyncer.stubs(:new).returns(syncer)

      ::Loaders::UexCommodityPricesJob.new.perform
    end

    test "#perform opens an issue for commodities that carry no UEX id" do
      stub_run(unknown: [])

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "uex_commodity_prices_import",
        title: "UEX Commodity Sync — Unmapped Commodities",
        body: anything
      ).returns(creator)

      ::Loaders::UexCommodityPricesJob.new.perform

      assert_equal ["items_commodities_ventslug"], Imports::UexCommodityPricesImport.last.output["unmapped"]
    end

    test "#perform opens an issue for priced commodities we do not carry" do
      stub_run(unmapped: [])

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "uex_commodity_prices_import",
        title: "UEX Commodity Sync — Priced Commodities We Do Not Carry",
        body: anything
      ).returns(creator)

      ::Loaders::UexCommodityPricesJob.new.perform

      assert_equal ["Aslarite"], Imports::UexCommodityPricesImport.last.output["unknown"]
    end

    test "#perform marks the import as failed when the sync raises" do
      mapper = mock("Uex::CommodityMapper")
      mapper.stubs(:run).returns(mapping_result(unmapped: []))
      ::Uex::CommodityMapper.stubs(:new).returns(mapper)

      syncer = mock("Uex::CommodityPriceSyncer")
      syncer.stubs(:run).raises(::Uex::Error, "UEX API error 403 for commodities_prices_all")
      ::Uex::CommodityPriceSyncer.stubs(:new).returns(syncer)

      error = assert_raises(::Uex::Error) { ::Loaders::UexCommodityPricesJob.new.perform }

      import = Imports::UexCommodityPricesImport.last

      assert_equal "failed", import.aasm_state
      assert_equal error.message, import.info
    end

    test "the unknown issue body carries nothing that changes when only prices move" do
      unknown = [{"id_commodity" => 999, "commodity_name" => "Aslarite"}]

      first = ::Uex::CommodityPriceSyncer.github_issue_body(sync_result(unknown:))
      second = ::Uex::CommodityPriceSyncer.github_issue_body(
        ::Uex::CommodityPriceSyncer::Result.new(created: 0, updated: 97, removed: 3, skipped_removals: 2, unknown:)
      )

      assert_equal first, second,
        "a volatile body would defeat GithubIssueCreator's digest and open an issue every day"
    end

    private def mapping_result(unmapped: [Commodity.new(name: "Vent Slug", sc_key: "items_commodities_ventslug")])
      ::Uex::CommodityMapper::Result.new(mapped: 7, updated: 2, unmatched: [], unmapped:)
    end

    private def sync_result(unknown: [{"id_commodity" => 999, "commodity_name" => "Aslarite"}])
      ::Uex::CommodityPriceSyncer::Result.new(created: 4, updated: 1, removed: 2, skipped_removals: 0, unknown:)
    end

    private def stub_run(unmapped: nil, unknown: nil)
      mapper = mock("Uex::CommodityMapper")
      mapper.expects(:run).returns(unmapped.nil? ? mapping_result : mapping_result(unmapped:))
      ::Uex::CommodityMapper.stubs(:new).returns(mapper)

      syncer = mock("Uex::CommodityPriceSyncer")
      syncer.expects(:run).returns(unknown.nil? ? sync_result : sync_result(unknown:))
      ::Uex::CommodityPriceSyncer.stubs(:new).returns(syncer)
    end
  end
end
