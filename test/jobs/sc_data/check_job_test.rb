# frozen_string_literal: true

require "test_helper"

module ScData
  class CheckJobTest < ActiveJob::TestCase
    VERSION = "3.24.0"
    PTU_VERSION = "3.24.1-ptu.2"
    ENVIRONMENT = "live"

    setup do
      Rails.configuration.stubs(:sc_data).returns({sources: {ENVIRONMENT.to_sym => VERSION}, default: ENVIRONMENT})
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
      Imports::ScData::AllImport.stubs(:finished).returns(
        stub(where: stub(count: ::ScData::CheckJob::MAX_IMPORTS_PER_VERSION))
      )

      # Both sources report two finished imports through the stub, so only the
      # one the config still needs is asked for -- which here is neither. The
      # point is that the count is asked per source rather than once.
      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    # Otherwise a catalogue the export has stopped shipping for good would
    # reload the whole of sc_data every night.
    test "#perform stops retrying a version the loaders have already had two goes at" do
      stub_finished_imports(::ScData::CheckJob::MAX_IMPORTS_PER_VERSION)
      load_every_catalogue
      Commodity.update_all(version: nil)

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    private def stub_finished_imports(count)
      Imports::ScData::AllImport.stubs(:finished).returns(stub(where: stub(count:)))
    end

    private def load_every_catalogue
      create(:component, version: VERSION)
      create(:commodity, version: VERSION)
      create(:equipment, version: VERSION)
    end
  end
end
