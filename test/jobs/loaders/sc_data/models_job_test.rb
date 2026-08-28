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

      # The load only iterates models that already exist, so a ship in the game
      # files with no row is invisible to it. These pin that the job says so.
      test "#perform reports the ships the game files describe and we have no model for" do
        @admin_user = create(:admin_user, resource_access: [:models])
        AdminNotificationsChannel.stubs(:broadcast_to)
        SC_DATA_STUB.call
        ::ScData::Loader::ModelsLoader.any_instance.stubs(:all)
        ::ScData::Loader::ModelsLoader.any_instance.stubs(:stats).returns({})
        ::Loaders::ScData::ModelsJob.any_instance.stubs(:fetch_parsed_tree!)

        entry = create(:sc_data_unlisted_model, identifier: "krig_s65_stingray", name: "Kruger S-65 Stingray")
        ::ScData::UnlistedModels.any_instance.stubs(:run)
          .returns({seen: 1, new: [entry], undecided: [entry]})

        creator = mock("GithubIssueCreator")
        creator.expects(:run)
        GithubIssueCreator.stubs(:new).returns(creator)

        ::Loaders::ScData::ModelsJob.new.perform

        notification = AdminNotification.find_by(
          admin_user: @admin_user, notification_type: "sc_data_unlisted_models"
        )
        assert_not_nil notification
        assert_equal "warning", notification.severity
        assert_includes notification.body, "krig_s65_stingray"
      end

      # Only a genuinely new entry is worth an issue, or a pile that has been
      # sitting undecided would reopen one on every patch.
      test "#perform opens no issue when nothing is new" do
        @admin_user = create(:admin_user, resource_access: [:models])
        AdminNotificationsChannel.stubs(:broadcast_to)
        SC_DATA_STUB.call
        ::ScData::Loader::ModelsLoader.any_instance.stubs(:all)
        ::ScData::Loader::ModelsLoader.any_instance.stubs(:stats).returns({})
        ::Loaders::ScData::ModelsJob.any_instance.stubs(:fetch_parsed_tree!)

        entry = create(:sc_data_unlisted_model)
        ::ScData::UnlistedModels.any_instance.stubs(:run)
          .returns({seen: 1, new: [], undecided: [entry]})
        GithubIssueCreator.expects(:new).never

        ::Loaders::ScData::ModelsJob.new.perform

        notification = AdminNotification.find_by(
          admin_user: @admin_user, notification_type: "sc_data_unlisted_models"
        )
        assert_equal "info", notification.severity
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
