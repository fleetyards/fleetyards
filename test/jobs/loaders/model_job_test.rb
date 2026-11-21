# frozen_string_literal: true

require "test_helper"
require "support/import_wrapping_job_tests"

module Loaders
  class ModelJobTest < ActiveJob::TestCase
    include ImportWrappingJobTests

    setup do
      @model = create(:model, rsi_id: 123)
    end

    test "#perform creates an import, runs the loader, and finishes the import" do
      assert_import_wrapping_job_success(
        job_class: ::Loaders::ModelJob,
        import_class: Imports::ModelImport,
        loader_class: Rsi::ModelsLoader,
        loader_method: :one_for,
        perform_args: [@model.id],
        loader_args: [@model]
      )
    end

    test "#perform marks import as failed on error" do
      assert_import_wrapping_job_failure(
        job_class: ::Loaders::ModelJob,
        import_class: Imports::ModelImport,
        loader_class: Rsi::ModelsLoader,
        loader_method: :one_for,
        perform_args: [@model.id]
      )
    end

    test "#perform fails the import when no matrix entry matches" do
      model = create(:model, name: "Nowhere On The Matrix", rsi_id: nil)
      Rsi::ModelsLoader.any_instance.stubs(:one_for).with(model).returns(false)

      ::Loaders::ModelJob.new.perform(model.id)

      import = Imports::ModelImport.last

      assert_equal "failed", import.aasm_state
      assert_equal "No ship matrix entry matches Nowhere On The Matrix", import.info
      assert_equal({"model_id" => model.id, "rsi_id" => nil}, import.input)
    end
  end
end
