# frozen_string_literal: true

require "test_helper"

module Loaders
  module ScData
    class AllJobTest < ActiveJob::TestCase
      setup do
        Rails.configuration.stubs(:sc_data).returns({version: "3.24.0"})
      end

      test "#perform creates an import, runs the loader, and finishes the import" do
        ::ScData::Loader::BaseLoader.expects(:all)

        ::Loaders::ScData::AllJob.new.perform

        import = Imports::ScData::AllImport.last
        assert import.present?
        assert_equal "finished", import.aasm_state
      end

      test "#perform marks import as failed on error" do
        ::ScData::Loader::BaseLoader.stubs(:all).raises(StandardError, "sc data error")

        error = assert_raises(StandardError) { ::Loaders::ScData::AllJob.new.perform }
        assert_equal "sc data error", error.message

        import = Imports::ScData::AllImport.last
        assert_equal "failed", import.aasm_state
        assert_equal "sc data error", import.info
      end
    end
  end
end
