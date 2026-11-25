# frozen_string_literal: true

require "test_helper"

module ScData
  class TracksRunTest < ActiveJob::TestCase
    class Run < ApplicationJob
      include TracksRun

      def perform(attached: {}, problems: [], &work)
        track_run(::Imports::ScData::ShipViewsImport) do
          @progress.step("ship_views", total: 2)
          problems.each { |problem| log(:warn, problem) }
          work&.call
          log(:info, "done")
          {attached:}
        end
      end
    end

    setup do
      @admin_user = create(:admin_user, resource_access: [:imports])
      ImportsChannel.stubs(:broadcast_to)
      AdminNotificationsChannel.stubs(:broadcast_to)
    end

    def import = Imports::ScData::ShipViewsImport.order(:created_at).last

    def notifications = AdminNotification.where(admin_user: @admin_user, notification_type: "import_run")

    test "keeps what a run attached and what it could not take in" do
      Run.new.perform(attached: {"aurora" => %w[holo top_view]}, problems: ["a.glb does not match"])

      assert_predicate import, :finished?
      assert_equal({"aurora" => %w[holo top_view]}, import.output["attached"])
      assert_equal ["a.glb does not match"], import.output["problems"]
      assert_equal "attached 2 files to 1 entries, 1 problem(s)", import.info
      assert_equal "ship_views", import.progress["step"]
      assert_equal "warning", notifications.sole.severity
    end

    test "stays quiet about a run that changed nothing" do
      Run.new.perform

      assert_equal "no files attached", import.info
      assert_empty notifications
    end

    test "stays quiet about a problem that is gone, or only worded differently" do
      Run.new.perform(problems: ["a failed: Timeout: request 1", "b failed: Timeout: request 2"])
      Run.new.perform(problems: ["b failed: Timeout: request 3", "a failed: Timeout: request 4"])
      Run.new.perform

      assert_equal 1, notifications.count
    end

    test "reports a problem once, and again when it changes" do
      2.times { Run.new.perform(problems: ["a is listed twice"]) }
      assert_equal 1, notifications.count

      Run.new.perform(problems: ["b is listed twice"])
      assert_equal 2, notifications.count
    end

    test "a run that raises fails its import and says why" do
      assert_raises(RuntimeError) { Run.new.perform { raise "no index" } }

      assert_predicate import, :failed?
      assert_equal "no index", import.info
    end

    test "leaves a run an admin cleared meanwhile as it is" do
      Run.new.perform { import.cleanup! }

      assert_predicate import, :failed?
      assert_nil import.output
    end
  end
end
