# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::LoanerJob do
  describe "#perform" do
    let(:loader) { instance_double(Rsi::LoanerLoader) }

    before do
      allow(Rsi::LoanerLoader).to receive(:new).and_return(loader)
      allow(ModelLoaner).to receive(:pluck).and_return([])
    end

    it "runs the loaner loader and cleans up orphaned loaners" do
      allow(loader).to receive(:run).and_return([[], []])

      described_class.new.perform

      expect(loader).to have_received(:run)
    end

    it "creates a GitHub issue when there are missing loaners" do
      allow(loader).to receive(:run).and_return([["Missing Loaner"], []])

      creator = instance_double(GithubIssueCreator, run: true)
      allow(GithubIssueCreator).to receive(:new).and_return(creator)

      described_class.new.perform

      expect(GithubIssueCreator).to have_received(:new).with(
        task_type: "loaner_sync",
        title: "Missing Loaners",
        body: anything
      )
      expect(creator).to have_received(:run)
    end
  end
end
