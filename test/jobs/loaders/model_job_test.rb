# frozen_string_literal: true

require "test_helper"
require_relative "../../support/import_wrapping_job_tests"

module Loaders
  class ModelJobTest < ActiveJob::TestCase
    include ImportWrappingJobTests

    test "#perform creates an import, runs the loader, and finishes the import" do
      assert_import_wrapping_job_success(
        job_class: ::Loaders::ModelJob,
        import_class: Imports::ModelImport,
        loader_class: Rsi::ModelsLoader,
        loader_method: :one,
        perform_args: [123],
        loader_args: [123]
      )
    end

    test "#perform marks import as failed on error" do
      assert_import_wrapping_job_failure(
        job_class: ::Loaders::ModelJob,
        import_class: Imports::ModelImport,
        loader_class: Rsi::ModelsLoader,
        loader_method: :one,
        perform_args: [123]
      )
    end
  end
end
