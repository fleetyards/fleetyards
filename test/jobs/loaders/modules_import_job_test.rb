# frozen_string_literal: true

require "test_helper"

module Loaders
  class ModulesImportJobTest < ActiveJob::TestCase
    test "#perform runs the modules importer and creates a GitHub issue" do
      results = {
        new: {count: 1, items: [{model_name: "Retaliator", name: "Front Torpedo Bay"}]},
        new_with_error: {count: 0, items: []},
        model_not_found: {count: 0, items: []}
      }

      importer = mock("ModulesImporter")
      importer.expects(:run).returns(results)
      ModulesImporter.stubs(:new).returns(importer)

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "modules_import",
        title: "Modules Import Results",
        body: anything
      ).returns(creator)

      ::Loaders::ModulesImportJob.new.perform
    end
  end
end
