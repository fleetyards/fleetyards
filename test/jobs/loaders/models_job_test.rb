# frozen_string_literal: true

require "test_helper"
require "support/import_wrapping_job_tests"

module Loaders
  class ModelsJobTest < ActiveJob::TestCase
    include ImportWrappingJobTests

    setup do
      @admin_user = create(:admin_user, resource_access: [:models])
      AdminNotificationsChannel.stubs(:broadcast_to)
    end

    test "#perform reports what the run changed" do
      Rsi::ModelsLoader.any_instance.stubs(:all).returns(nil)

      ::Loaders::ModelsJob.new.perform

      notification = AdminNotification.find_by(
        admin_user: @admin_user, notification_type: "ship_matrix_import"
      )

      assert_not_nil notification
      assert_equal "info", notification.severity
      assert_includes notification.body, "Models added"
    end

    # A quiet run is the normal case for a matrix that moves a few times a
    # month, so it must not open an issue nobody can close.
    test "#perform never opens an issue" do
      Rsi::ModelsLoader.any_instance.stubs(:all).returns(nil)
      GithubIssueCreator.expects(:new).never

      ::Loaders::ModelsJob.new.perform
    end

    test "#perform names the models the run added" do
      Rsi::ModelsLoader.any_instance.stubs(:all).with do
        create(:model, name: "Spirit C1")
        true
      end

      ::Loaders::ModelsJob.new.perform

      notification = AdminNotification.find_by(
        admin_user: @admin_user, notification_type: "ship_matrix_import"
      )

      assert_includes notification.body, "Spirit C1"
    end

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
