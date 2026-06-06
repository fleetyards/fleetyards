# frozen_string_literal: true

# Shared assertions for the import-wrapping job pattern.
# Tests that a job creates an import record, runs the loader, finishes the
# import on success, and marks it as failed on error.
#
# Usage:
#
#   class Loaders::ModelJobTest < ActiveJob::TestCase
#     include ImportWrappingJobTests
#
#     test "creates an import, runs the loader, and finishes the import" do
#       assert_import_wrapping_job_success(
#         job_class: Loaders::ModelJob,
#         import_class: Imports::ModelImport,
#         loader_class: Rsi::ModelsLoader,
#         loader_method: :one,
#         perform_args: [123],
#         loader_args: [123]
#       )
#     end
#
#     test "marks import as failed on error" do
#       assert_import_wrapping_job_failure(
#         job_class: Loaders::ModelJob,
#         import_class: Imports::ModelImport,
#         loader_class: Rsi::ModelsLoader,
#         loader_method: :one,
#         perform_args: [123]
#       )
#     end
#   end

module ImportWrappingJobTests
  def assert_import_wrapping_job_success(job_class:, import_class:, loader_class:, loader_method:, perform_args: [], loader_args: [], before_perform: nil)
    loader = mock("loader")
    loader_class.stubs(:new).returns(loader)
    if loader_args.empty?
      loader.expects(loader_method)
    else
      loader.expects(loader_method).with(*loader_args)
    end

    instance_exec(&before_perform) if before_perform

    job_class.new.perform(*perform_args)

    import = import_class.last
    assert import.present?, "expected an #{import_class} record to exist"
    assert_equal "finished", import.aasm_state
  end

  def assert_import_wrapping_job_failure(job_class:, import_class:, loader_class:, loader_method:, perform_args: [], before_perform: nil)
    loader = mock("loader")
    loader_class.stubs(:new).returns(loader)
    loader.stubs(loader_method).raises(StandardError, "loader error")

    instance_exec(&before_perform) if before_perform

    error = assert_raises(StandardError) { job_class.new.perform(*perform_args) }
    assert_equal "loader error", error.message

    import = import_class.last
    assert_equal "failed", import.aasm_state
    assert_equal "loader error", import.info
  end
end
