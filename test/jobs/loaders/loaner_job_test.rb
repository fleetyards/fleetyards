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

    # `add_loaners` runs over every vehicle of every loaner-bearing model, so
    # without the guard this job alone would file versions at the scale of the
    # whole hangar.
    test "#perform records no versions, though it writes a versioned column" do
      ModelLoaner.unstub(:pluck)
      @loader.stubs(:run).returns([[], []])

      user = create(:user)
      loaner_model = create(:model)
      parent_model = create(:model).tap { |model| model.loaners << loaner_model }
      parent = create(:vehicle, user:, model: parent_model, wanted: false)
      Vehicle.where(loaner: true, vehicle_id: parent.id).destroy_all

      assert_no_difference -> { PaperTrail::Version.where(item_type: "Vehicle").count } do
        ::Loaders::LoanerJob.new.perform
      end

      assert_predicate Vehicle.where(loaner: true, vehicle_id: parent.id), :any?,
        "the job did no work, so it proved nothing"
    end

    test "#perform creates a GitHub issue when there are missing loaners" do
      missing_loaners = [{loaner: "F7C Hornet", model: "Mole", model_id: "abc-123"}]
      @loader.stubs(:run).returns([missing_loaners, []])

      creator = mock("GithubIssueCreator")
      creator.expects(:run).returns(true)
      GithubIssueCreator.expects(:new).with(
        task_type: "loaner_sync",
        report_key: nil,
        title: "Missing Loaners",
        body: anything
      ).returns(creator)

      ::Loaders::LoanerJob.new.perform
    end
  end
end
