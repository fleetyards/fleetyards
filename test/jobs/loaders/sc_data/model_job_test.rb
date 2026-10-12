# frozen_string_literal: true

require "test_helper"

module Loaders
  module ScData
    class ModelJobTest < ActiveJob::TestCase
      test "#perform creates an import, runs the loader, and finishes the import" do
        model = create(:model)
        loader = mock("ScData::Loader::ModelsLoader")
        loader.stubs(:stats).returns({})
        loader.expects(:one).with(model)
        ::ScData::Loader::ModelsLoader.stubs(:new).returns(loader)

        ::Loaders::ScData::ModelJob.new.perform(model.id)

        import = Imports::ScData::ModelImport.last
        assert import.present?
        assert_equal "finished", import.aasm_state
      end

      test "#perform marks import as failed on error" do
        model = create(:model)
        loader = mock("ScData::Loader::ModelsLoader")
        loader.stubs(:stats).returns({})
        loader.stubs(:one).raises(StandardError, "sc data error")
        ::ScData::Loader::ModelsLoader.stubs(:new).returns(loader)

        error = assert_raises(StandardError) { ::Loaders::ScData::ModelJob.new.perform(model.id) }
        assert_equal "sc data error", error.message

        import = Imports::ScData::ModelImport.last
        assert_equal "failed", import.aasm_state
        assert_equal "sc data error", import.info
      end

      test "#perform goes back on the queue while a full load holds the lock" do
        model = create(:model)
        ActiveRecord::Base.stubs(:with_advisory_lock_result)
          .returns(WithAdvisoryLock::Result.new(lock_was_acquired: false))
        ::ScData::Loader::ModelsLoader.expects(:new).never

        ::Loaders::ScData::ModelJob.jobs.clear
        ::Loaders::ScData::ModelJob.new.perform(model.id)

        assert_nil Imports::ScData::ModelImport.last
        assert_equal [[model.id]], ::Loaders::ScData::ModelJob.jobs.map { |job| job["args"] }
      end
    end
  end
end
