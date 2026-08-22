# frozen_string_literal: true

require "test_helper"
require "support/import_wrapping_job_tests"

module Loaders
  module ScData
    class ModelsJobTest < ActiveJob::TestCase
      include ImportWrappingJobTests

      SC_DATA_STUB = -> { Rails.configuration.stubs(:sc_data).returns({version: "3.24.0", environment: "live"}) }

      test "#perform creates an import, runs the loader, and finishes the import" do
        assert_import_wrapping_job_success(
          job_class: ::Loaders::ScData::ModelsJob,
          import_class: Imports::ScData::ModelsImport,
          loader_class: ::ScData::Loader::ModelsLoader,
          loader_method: :all,
          before_perform: SC_DATA_STUB
        )
      end

      test "#perform marks import as failed on error" do
        assert_import_wrapping_job_failure(
          job_class: ::Loaders::ScData::ModelsJob,
          import_class: Imports::ScData::ModelsImport,
          loader_class: ::ScData::Loader::ModelsLoader,
          loader_method: :all,
          before_perform: SC_DATA_STUB
        )
      end
    end
  end
end
