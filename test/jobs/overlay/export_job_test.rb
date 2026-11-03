# frozen_string_literal: true

require "test_helper"

module Overlay
  class ExportJobTest < ActiveSupport::TestCase
    test "builds and publishes the channel it was given" do
      result = Export::Result.new(manifest: {count: 0}, items_gzip: "".b, file_name: "items.x.json.gz")
      Export.any_instance.expects(:build).returns(result)
      Publisher.any_instance.expects(:publish).with(result).returns(:published)

      ExportJob.new.perform("live")
    end

    test "covers every configured channel when given none" do
      result = Export::Result.new(manifest: {count: 0}, items_gzip: "".b, file_name: "items.x.json.gz")
      Export.stubs(:channels).returns(%w[live ptu])
      Export.expects(:new).with("live").returns(stub(build: result))
      Export.expects(:new).with("ptu").returns(stub(build: result))
      Publisher.any_instance.expects(:publish).twice.returns(:unchanged)

      ExportJob.new.perform
    end
  end
end
