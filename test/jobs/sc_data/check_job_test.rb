# frozen_string_literal: true

require "test_helper"

module ScData
  class CheckJobTest < ActiveJob::TestCase
    VERSION = "3.24.0"
    PTU_VERSION = "3.24.1-ptu.2"
    ENVIRONMENT = "live"

    setup do
      Rails.configuration.stubs(:sc_data).returns({sources: {ENVIRONMENT.to_sym => VERSION}, default: ENVIRONMENT})

      # Unconfigured unless a test says otherwise: without a bucket the tree
      # check has nothing to compare and must not change what the rest decide.
      ::ScData::ParsedStore.stubs(:configured?).returns(false)
    end

    test "#perform enqueues AllJob when version is new" do
      stub_finished_imports(0)

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    test "#perform does not enqueue AllJob when version is blank" do
      Rails.configuration.stubs(:sc_data).returns({sources: {ENVIRONMENT.to_sym => nil}, default: ENVIRONMENT})

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    test "#perform does not enqueue AllJob when the version is imported and every catalogue carries it" do
      stub_finished_imports(1)
      load_every_catalogue

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # The version guard on its own let a loader added to BaseLoader.all after the
    # current build was imported sit unrun until the next patch moved the version.
    test "#perform enqueues AllJob when the version is imported but a catalogue was never loaded" do
      stub_finished_imports(1)
      load_every_catalogue
      CommodityBuild.delete_all

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    # The coverage check reads the build rows, not the catalogues' own `version`
    # columns. Those are shared between environments and a load rewrites every
    # one of them, so a ptu load would otherwise make this re-enqueue a live
    # load that had already finished.
    test "#perform ignores the catalogues' version columns" do
      stub_finished_imports(1)
      load_every_catalogue
      Component.update_all(version: "9.9.9-ptu.1")
      Commodity.update_all(version: "9.9.9-ptu.1")
      Equipment.update_all(version: "9.9.9-ptu.1")

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # A ptu build reaching the bucket and the config and then never being loaded
    # is the gap this closes -- and it was quiet, because nothing complained.
    test "#perform enqueues a load for every configured source, not only the default" do
      Rails.configuration.stubs(:sc_data).returns({
        sources: {live: VERSION, ptu: PTU_VERSION}, default: ENVIRONMENT
      })
      stub_finished_imports(0)

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, "live")
      Loaders::ScData::AllJob.expects(:perform_async).with(PTU_VERSION, nil, "ptu")

      ::ScData::CheckJob.new.perform
    end

    test "#perform leaves a source alone that is already loaded and enqueues the other" do
      Rails.configuration.stubs(:sc_data).returns({
        sources: {live: VERSION, ptu: PTU_VERSION}, default: ENVIRONMENT
      })
      stub_finished_imports(::ScData::CheckJob::MAX_IMPORTS_PER_TREE)
      stub_finished_imports(::ScData::CheckJob::MAX_IMPORTS_PER_TREE, version: PTU_VERSION)

      # Both sources have had their two goes, so neither is asked for. The point
      # is that the ledger is read per source rather than once.
      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # Otherwise a catalogue the export has stopped shipping for good would
    # reload the whole of sc_data every night.
    test "#perform stops retrying a version the loaders have already had two goes at" do
      stub_finished_imports(::ScData::CheckJob::MAX_IMPORTS_PER_TREE)
      load_every_catalogue
      Commodity.update_all(version: nil)

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # Real rows rather than a stubbed relation: the tree check reads the last
    # finished import's own checksum, so there has to be a record to read it
    # from.
    # The gap this closes. A parser change rewrites the tree and leaves the
    # version alone, so the version could never answer "is this the tree I
    # already loaded?" -- and a pushed re-parse reached nobody until a human
    # triggered a load.
    test "#perform enqueues AllJob when the bucket holds a tree the last load did not read" do
      stub_finished_imports(1, checksum: "old-tree")
      load_every_catalogue
      stub_remote_checksum("new-tree")

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    test "#perform leaves a source alone when the bucket holds the tree it loaded" do
      stub_finished_imports(1, checksum: "same-tree")
      load_every_catalogue
      stub_remote_checksum("same-tree")

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # A load recorded before checksums existed carries none, so the first run
    # after this ships reloads each source exactly once -- which is how a tree
    # that was pushed months ago finally reaches production.
    test "#perform enqueues AllJob for a load that recorded no tree at all" do
      stub_finished_imports(1)
      load_every_catalogue
      stub_remote_checksum("any-tree")

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    # The tree check sits above the two-goes ceiling on purpose. That ceiling
    # guards a guess about a future build; this is not a guess, and a tree that
    # has genuinely changed has to be loaded however many times the version has
    # been tried.
    test "#perform reloads a changed tree even after the version has had its two goes" do
      stub_finished_imports(::ScData::CheckJob::MAX_IMPORTS_PER_TREE, checksum: "old-tree")
      load_every_catalogue
      stub_remote_checksum("new-tree")

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    # Reloading the whole of sc_data because the bucket blinked is far worse
    # than waiting for tomorrow's run.
    test "#perform does not reload when the bucket cannot be read" do
      stub_finished_imports(1, checksum: "old-tree")
      load_every_catalogue
      ::ScData::ParsedStore.stubs(:configured?).returns(true)
      ::ScData::ParsedStore.stubs(:new).raises(Aws::S3::Errors::ServiceError.new(nil, "no"))

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # Nothing serialises a load -- the nightly check and the admin reload can
    # both enqueue one -- so the load started second is not always the one that
    # finished second. Reading the newest *created* record would answer with a
    # tree the database does not reflect.
    test "#perform reads the load that finished last, not the one created last" do
      earlier = Imports::ScData::AllImport.create!(
        version: VERSION, aasm_state: "finished", tree_checksum: "new-tree"
      )
      later = Imports::ScData::AllImport.create!(
        version: VERSION, aasm_state: "finished", tree_checksum: "old-tree"
      )
      # Created first, finished last.
      earlier.update!(finished_at: 1.minute.from_now)
      later.update!(finished_at: 2.minutes.ago)

      load_every_catalogue
      stub_remote_checksum("new-tree")

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # A record moved to `finished` without the state machine has no
    # `finished_at`, and Postgres sorts nulls first on a descending order -- so
    # it would otherwise win over every record that actually knows something.
    test "#perform prefers a load that recorded when it finished" do
      Imports::ScData::AllImport.create!(
        version: VERSION, aasm_state: "finished", tree_checksum: nil, finished_at: nil
      )
      Imports::ScData::AllImport.create!(
        version: VERSION, aasm_state: "finished", tree_checksum: "same-tree", finished_at: 1.minute.ago
      )

      load_every_catalogue
      stub_remote_checksum("same-tree")

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # The ceiling counts loads of *this tree*, not of the version. Counting by
    # version let a checksum-driven reload burn the coverage budget: the build
    # already had one import, the reload made two, and `VERSIONED_CATALOGUES`
    # became unreachable for it -- so a loader added afterwards would never run,
    # which is the failure the coverage check exists to catch.
    test "#perform still checks catalogue coverage after a tree reload used up the version's budget" do
      stub_finished_imports(1, checksum: "old-tree")
      stub_finished_imports(1, checksum: "new-tree")
      load_every_catalogue
      CommodityBuild.delete_all
      stub_remote_checksum("new-tree")

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    # And it is still a ceiling: two goes at the same tree and it stops, or a
    # catalogue the export has dropped for good would reload every night.
    test "#perform stops retrying a tree the loaders have already had two goes at" do
      stub_finished_imports(::ScData::CheckJob::MAX_IMPORTS_PER_TREE, checksum: "same-tree")
      load_every_catalogue
      CommodityBuild.delete_all
      stub_remote_checksum("same-tree")

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # Blueprints arrived after the build they shipped on had been imported, and
    # were missing from the coverage list until the checksum work went in.
    test "#perform enqueues AllJob when blueprints were never loaded" do
      stub_finished_imports(1)
      load_every_catalogue
      BlueprintBuild.delete_all

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION, nil, ENVIRONMENT)

      ::ScData::CheckJob.new.perform
    end

    private def stub_finished_imports(count, version: VERSION, checksum: nil, finished_at: Time.current)
      count.times do |index|
        Imports::ScData::AllImport.create!(
          version:, aasm_state: "finished", tree_checksum: checksum,
          finished_at: finished_at + index.seconds
        )
      end
    end

    private def load_every_catalogue
      create(:component, version: VERSION)
      create(:commodity, version: VERSION)
      create(:equipment, version: VERSION)
      create(:blueprint, version: VERSION)
    end

    private def stub_remote_checksum(checksum, environment: ENVIRONMENT)
      ::ScData::ParsedStore.stubs(:configured?).returns(true)
      ::ScData::ParsedStore
        .stubs(:new)
        .with(environment)
        .returns(stub(remote_checksum: checksum))
    end
  end
end
