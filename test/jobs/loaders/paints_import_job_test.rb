# frozen_string_literal: true

require "test_helper"

module Loaders
  class PaintsImportJobTest < ActiveJob::TestCase
    setup do
      @admin_user = create(:admin_user, resource_access: [:models])
      AdminNotificationsChannel.stubs(:broadcast_to)
    end

    def stub_importer(results, model: nil)
      importer = mock("PaintsImporter")
      importer.expects(:run).returns(results)
      PaintsImporter.stubs(:new).with(model:).returns(importer)
    end

    def results(new: [], new_with_error: [], model_not_found: [])
      {
        new: {count: new.size, items: new},
        new_with_error: {count: new_with_error.size, items: new_with_error},
        model_not_found: {count: model_not_found.size, items: model_not_found}
      }
    end

    test "#perform notifies admins without opening an issue when nothing needs doing" do
      stub_importer(results(new: [{model_name: "Aurora", name: "Red Alert"}]))
      GithubIssueCreator.expects(:new).never

      ::Loaders::PaintsImportJob.new.perform

      notification = AdminNotification.find_by(admin_user: @admin_user, notification_type: "paints_import")
      assert_not_nil notification
      assert_equal "info", notification.severity
    end

    test "#perform opens an issue when models are missing" do
      stub_importer(results(model_not_found: [{model_name: "Unknown", name: "Red Alert"}]))

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "paints_import",
        report_key: nil,
        title: "Paints Import Results",
        body: anything
      ).returns(creator)

      ::Loaders::PaintsImportJob.new.perform

      assert_equal "warning", AdminNotification.find_by(admin_user: @admin_user).severity
    end

    test "#perform opens an issue when paints failed to import" do
      stub_importer(results(new_with_error: [{model_name: "Aurora", name: "Red Alert"}]))

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).returns(creator)

      ::Loaders::PaintsImportJob.new.perform
    end

    test "#perform for a single model runs the importer for that model only" do
      model = create(:model)
      stub_importer(results(new: [{model_name: model.name, name: "Red Alert"}]), model:)

      ::Loaders::PaintsImportJob.new.perform(nil, model.id)

      import = Imports::PaintsImport.sole
      assert_equal({"model_id" => model.id}, import.input)
      assert import.finished?
      notification = AdminNotification.find_by(notification_type: "paints_import")
      assert_equal "Paints Import Results for #{model.name}", notification.title
    end

    test "#perform for a single model keeps its issue dedupe separate from the full run" do
      model = create(:model)
      stub_importer(results(new_with_error: [{model_name: model.name, name: "Red Alert"}]), model:)

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "paints_import",
        report_key: "paints_import_#{model.id}",
        title: "Paints Import Results for #{model.name}",
        body: anything
      ).returns(creator)

      ::Loaders::PaintsImportJob.new.perform(nil, model.id)
    end

    test "#perform folds an unchanged empty report into one notification" do
      2.times do
        stub_importer(results)
        ::Loaders::PaintsImportJob.new.perform
      end

      assert_equal 1, AdminNotification.where(notification_type: "paints_import").count
      assert_equal 2, AdminNotification.find_by(notification_type: "paints_import").occurrences
    end
  end
end
