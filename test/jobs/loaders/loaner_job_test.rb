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

    # The imports page reads a running load off its import, and a loaner run
    # had none to read.
    test "#perform records its run as an import" do
      @loader.stubs(:run).returns([[], []])

      ::Loaders::LoanerJob.new.perform

      assert_predicate Imports::LoanersImport.last, :finished?
    end

    # The run files its own report; the import's own "finished" would repeat it.
    test "#perform reports a clean run once" do
      @loader.stubs(:run).returns([[], []])
      create(:admin_user, resource_access: [:imports])

      assert_no_difference -> { AdminNotification.where(notification_type: "import_run").count } do
        ::Loaders::LoanerJob.new.perform
      end
    end

    test "#perform marks the import failed when the loader raises" do
      @loader.stubs(:run).raises(StandardError, "RSI is down")

      assert_raises(StandardError) { ::Loaders::LoanerJob.new.perform }

      import = Imports::LoanersImport.last
      assert_predicate import, :failed?
      assert_equal "RSI is down", import.info
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

    # The loaner model is still lent by another ship, so the model-wide cleanup
    # keeps it; only the dropped pairing says this row should go.
    test "#perform removes a loaner whose pairing RSI dropped" do
      ModelLoaner.unstub(:pluck)
      @loader.stubs(:run).returns([[], []])

      user = create(:user)
      loaner_model = create(:model)
      parent_model = create(:model).tap { |model| model.loaners << loaner_model }
      create(:model).tap { |model| model.loaners << loaner_model }
      parent = create(:vehicle, user:, model: parent_model, wanted: false)
      ModelLoaner.where(model: parent_model).delete_all

      ::Loaders::LoanerJob.new.perform

      assert_empty Vehicle.where(loaner: true, vehicle_id: parent.id)
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
