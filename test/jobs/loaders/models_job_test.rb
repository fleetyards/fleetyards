# frozen_string_literal: true

require "test_helper"
require_relative "../../support/import_wrapping_job_tests"

module Loaders
  class ModelsJobTest < ActiveJob::TestCase
    include ImportWrappingJobTests

    test "#perform creates an import, runs the loader, and finishes the import" do
      assert_import_wrapping_job_success(
        job_class: ::Loaders::ModelsJob,
        import_class: Imports::ModelsImport,
        loader_class: Rsi::ModelsLoader,
        loader_method: :all
      )
    end

    test "#perform marks import as failed on error" do
      assert_import_wrapping_job_failure(
        job_class: ::Loaders::ModelsJob,
        import_class: Imports::ModelsImport,
        loader_class: Rsi::ModelsLoader,
        loader_method: :all
      )
    end
  end
end
