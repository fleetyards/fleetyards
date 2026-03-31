# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::PaintsImportJob do
  describe "#perform" do
    it "runs the paints importer and creates a GitHub issue" do
      results = {
        new: {count: 1, items: [{model_name: "Aurora", name: "Red Alert"}]},
        new_with_error: {count: 0, items: []},
        model_not_found: {count: 0, items: []}
      }

      importer = instance_double(PaintsImporter)
      allow(PaintsImporter).to receive(:new).and_return(importer)
      allow(importer).to receive(:run).and_return(results)

      creator = instance_double(GithubIssueCreator, run: true)
      allow(GithubIssueCreator).to receive(:new).and_return(creator)

      described_class.new.perform

      expect(importer).to have_received(:run)
      expect(GithubIssueCreator).to have_received(:new).with(
        task_type: "paints_import",
        title: "Paints Import Results",
        body: anything
      )
      expect(creator).to have_received(:run)
    end
  end
end
