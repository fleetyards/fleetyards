# frozen_string_literal: true

require "test_helper"

module ScData
  class CheckJobTest < ActiveJob::TestCase
    VERSION = "3.24.0"

    setup do
      Rails.configuration.stubs(:sc_data).returns({version: VERSION})
    end

    test "#perform enqueues AllJob when version is new" do
      stub_finished_imports(0)

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION)

      ::ScData::CheckJob.new.perform
    end

    test "#perform does not enqueue AllJob when version is blank" do
      Rails.configuration.stubs(:sc_data).returns({version: nil})

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
      Commodity.update_all(version: nil)

      Loaders::ScData::AllJob.expects(:perform_async).with(VERSION)

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
