# frozen_string_literal: true

require "test_helper"

module Loaders
  class UexPricesJobTest < ActiveJob::TestCase
    test "#perform syncs prices and records the counts on the import" do
      stub_syncer(unmatched: [])

      GithubIssueCreator.expects(:new).never

      ::Loaders::UexPricesJob.new.perform

      import = Imports::UexPricesImport.last

      assert_equal "finished", import.aasm_state
      assert_equal(
        {"created" => 4, "updated" => 1, "removed" => 2, "skipped_removals" => 0, "repriced" => 3, "unmatched" => []},
        import.output
      )
    end

    test "#perform opens a GitHub issue when a vehicle resolves to no model" do
      stub_syncer

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "uex_prices_import",
        report_key: nil,
        title: "UEX Price Sync — Unmatched Vehicles",
        body: anything
      ).returns(creator)

      ::Loaders::UexPricesJob.new.perform

      assert_equal ["nova-tank"], Imports::UexPricesImport.last.output["unmatched"]
    end

    test "the issue body carries nothing that changes when only prices move" do
      unmatched = [{"slug" => "nova-tank", "name" => "Nova Tank", "name_full" => "Tumbril Nova Tank"}]

      first = ::Uex::PriceSyncer.github_issue_body(
        ::Uex::PriceSyncer::Result.new(created: 4, updated: 1, removed: 2, skipped_removals: 0, unmatched:)
      )
      second = ::Uex::PriceSyncer.github_issue_body(
        ::Uex::PriceSyncer::Result.new(created: 0, updated: 97, removed: 3, skipped_removals: 2, unmatched:)
      )

      assert_equal first, second,
        "a volatile body would defeat GithubIssueCreator's digest and open an issue every day"
    end

    test "#perform marks the import as failed when the sync raises" do
      syncer = mock("Uex::PriceSyncer")
      syncer.stubs(:run).raises(::Uex::Error, "UEX API error 403 for vehicles")
      ::Uex::PriceSyncer.stubs(:new).returns(syncer)

      error = assert_raises(::Uex::Error) { ::Loaders::UexPricesJob.new.perform }

      assert_equal "UEX API error 403 for vehicles", error.message

      import = Imports::UexPricesImport.last

      assert_equal "failed", import.aasm_state
      assert_equal "UEX API error 403 for vehicles", import.info
    end

    test "the unmatched issue body names the vehicles to add to MAPPINGS" do
      result = ::Uex::PriceSyncer::Result.new(
        created: 0, updated: 0, removed: 0, skipped_removals: 0,
        unmatched: [{"slug" => "nova-tank", "name" => "Nova Tank", "name_full" => "Tumbril Nova Tank"}]
      )

      body = ::Uex::PriceSyncer.github_issue_body(result)

      assert_match "Unmatched UEX Vehicles (1)", body
      assert_match "Tumbril Nova Tank", body
      assert_match "nova-tank", body
      assert_match "Uex::VehicleMatcher::MAPPINGS", body
    end

    private def stub_syncer(unmatched: [{"slug" => "nova-tank", "name" => "Nova Tank", "name_full" => "Tumbril Nova Tank"}])
      result = ::Uex::PriceSyncer::Result.new(created: 4, updated: 1, removed: 2, skipped_removals: 0, repriced: 3, unmatched:)

      syncer = mock("Uex::PriceSyncer")
      syncer.expects(:run).returns(result)
      ::Uex::PriceSyncer.stubs(:new).returns(syncer)
    end
  end
end
