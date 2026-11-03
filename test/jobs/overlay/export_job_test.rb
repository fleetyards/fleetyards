# frozen_string_literal: true

require "test_helper"

module Overlay
  class ExportJobTest < ActiveSupport::TestCase
    setup do
      Publisher.stubs(:configured?).returns(true)
    end

    test "builds and publishes the channel it was given" do
      result = Export::Result.new(manifest: {count: 0}, items_gzip: "".b, file_name: "items.x.json.gz")
      Export.any_instance.expects(:build).returns(result)
      Publisher.any_instance.expects(:publish).with(result).returns(:published)

      ExportJob.new.perform("live")
    end

    test "hands every configured channel a run of its own when given none" do
      Export.stubs(:channels).returns(%w[live ptu])
      Export.expects(:new).never

      assert_difference -> { ExportJob.jobs.size }, 2 do
        ExportJob.new.perform
      end
      assert_equal [["live"], ["ptu"]], ExportJob.jobs.last(2).map { |job| job["args"] }
    end

    test "does nothing where the public storage bucket is not configured" do
      Publisher.stubs(:configured?).returns(false)
      Export.expects(:new).never

      assert_no_difference -> { ExportJob.jobs.size } do
        ExportJob.new.perform("live")
      end
    end
  end
end
