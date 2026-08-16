# frozen_string_literal: true

require "test_helper"

module Loaders
  class PaintsImportJobTest < ActiveJob::TestCase
    test "#perform runs the paints importer and creates a GitHub issue" do
      results = {
        new: {count: 1, items: [{model_name: "Aurora", name: "Red Alert"}]},
        new_with_error: {count: 0, items: []},
        model_not_found: {count: 0, items: []}
      }

      importer = mock("PaintsImporter")
      importer.expects(:run).returns(results)
      PaintsImporter.stubs(:new).returns(importer)

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "paints_import",
        title: "Paints Import Results",
        body: anything
      ).returns(creator)

      ::Loaders::PaintsImportJob.new.perform
    end
  end
end
