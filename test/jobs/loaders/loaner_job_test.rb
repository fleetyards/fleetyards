# frozen_string_literal: true

require "test_helper"

module Loaders
  class LoanerJobTest < ActiveJob::TestCase
    setup do
      @loader = mock("Rsi::LoanerLoader")
      Rsi::LoanerLoader.stubs(:new).returns(@loader)
      ModelLoaner.stubs(:pluck).returns([])
    end

    test "#perform runs the loaner loader and cleans up orphaned loaners" do
      @loader.expects(:run).returns([[], []])

      ::Loaders::LoanerJob.new.perform
    end

    test "#perform creates a GitHub issue when there are missing loaners" do
      missing_loaners = [{loaner: "F7C Hornet", model: "Mole", model_id: "abc-123"}]
      @loader.stubs(:run).returns([missing_loaners, []])

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "loaner_sync",
        title: "Missing Loaners",
        body: anything
      ).returns(creator)

      ::Loaders::LoanerJob.new.perform
    end
  end
end
