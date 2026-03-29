# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ModulesImportJob do
  describe "#perform" do
    it "runs the modules importer and creates a GitHub issue" do
      results = {
        new: {count: 1, items: [{model_name: "Retaliator", name: "Front Torpedo Bay"}]},
        new_with_error: {count: 0, items: []},
        model_not_found: {count: 0, items: []}
      }

      importer = instance_double(ModulesImporter)
      allow(ModulesImporter).to receive(:new).and_return(importer)
      allow(importer).to receive(:run).and_return(results)

      creator = instance_double(GithubIssueCreator, run: true)
      allow(GithubIssueCreator).to receive(:new).and_return(creator)

      described_class.new.perform

      expect(importer).to have_received(:run)
      expect(GithubIssueCreator).to have_received(:new).with(
        task_type: "modules_import",
        title: "Modules Import Results",
        body: anything
      )
      expect(creator).to have_received(:run)
    end
  end
end
