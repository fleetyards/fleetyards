# frozen_string_literal: true

require "test_helper"

module Loaders
  class ModulesImportJobTest < ActiveJob::TestCase
    setup do
      @admin_user = create(:admin_user, resource_access: [:models])
      AdminNotificationsChannel.stubs(:broadcast_to)
    end

    def stub_importer(results)
      importer = mock("ModulesImporter")
      importer.expects(:run).returns(results)
      ModulesImporter.stubs(:new).returns(importer)
    end

    def results(new: [], new_with_error: [], model_not_found: [])
      {
        new: {count: new.size, items: new},
        new_with_error: {count: new_with_error.size, items: new_with_error},
        model_not_found: {count: model_not_found.size, items: model_not_found}
      }
    end

    test "#perform notifies admins without opening an issue when nothing needs doing" do
      stub_importer(results(new: [{model_name: "Retaliator", name: "Front Torpedo Bay"}]))
      GithubIssueCreator.expects(:new).never

      ::Loaders::ModulesImportJob.new.perform

      notification = AdminNotification.find_by(admin_user: @admin_user, notification_type: "modules_import")
      assert_not_nil notification
      assert_equal "info", notification.severity
    end

    test "#perform opens an issue when models are missing" do
      stub_importer(results(model_not_found: [{model_name: "Unknown", name: "Front Torpedo Bay"}]))

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "modules_import",
        report_key: nil,
        title: "Modules Import Results",
        body: anything
      ).returns(creator)

      ::Loaders::ModulesImportJob.new.perform

      assert_equal "warning", AdminNotification.find_by(admin_user: @admin_user).severity
    end
  end
end
