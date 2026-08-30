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

    test "#perform names the models the run updated, and the fields that moved" do
      model = create(:model, name: "Carrack", cargo: 456)

      Rsi::ModelsLoader.any_instance.stubs(:all).with do
        model.update!(cargo: 400)
        true
      end

      ::Loaders::ModelsJob.new.perform

      notification = AdminNotification.find_by(
        admin_user: @admin_user, notification_type: "ship_matrix_import"
      )

      assert_includes notification.body, "- **Carrack**: cargo"
    end

    # The matrix writes `rsi_mass` on every run but `mass` only when RSI moved
    # `time_modified`, so a shadow moving alone is a value we declined.
    test "#perform separates a matrix value the run did not adopt" do
      model = create(:model, name: "Idris P", mass: 40_000, rsi_mass: 40_000, cargo: 100)

      Rsi::ModelsLoader.any_instance.stubs(:all).with do
        model.update!(rsi_mass: 52_000, cargo: 120, rsi_cargo: 120)
        true
      end

      ::Loaders::ModelsJob.new.perform

      notification = AdminNotification.find_by(
        admin_user: @admin_user, notification_type: "ship_matrix_import"
      )

      assert_includes notification.body, "- **Idris P**: cargo (matrix only: mass)"
    end

    # The loader also writes `last_updated_at` and the store image, neither of
    # which paper_trail watches. Such a run still has a model to name.
    test "#perform names an updated model paper_trail did not watch" do
      model = create(:model, name: "Carrack")

      Rsi::ModelsLoader.any_instance.stubs(:all).with do
        model.update!(last_updated_at: Time.current)
        true
      end

      ::Loaders::ModelsJob.new.perform

      notification = AdminNotification.find_by(
        admin_user: @admin_user, notification_type: "ship_matrix_import"
      )

      assert_includes notification.body, "- **Carrack**"
      assert_not_includes notification.body, "- **Carrack**:"
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
