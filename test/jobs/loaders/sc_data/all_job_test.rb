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

      # The counts are the record of what a load did. A log line is not enough:
      # the admin view of an import is where somebody looks after a build lands
      # badly, and "changed nothing" has to be distinguishable there from
      # "rewrote the catalogue".
      test "#perform keeps what each loader did on the import" do
        ::ScData::Loader::BaseLoader.expects(:all).returns({
          "EquipmentLoader" => {"Equipment" => {created: 2, updated: 1, unchanged: 4818}}
        })

        ::Loaders::ScData::AllJob.new.perform

        output = Imports::ScData::AllImport.last.output

        assert_equal({"created" => 2, "updated" => 1, "unchanged" => 4818},
          output.dig("EquipmentLoader", "Equipment"))
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
