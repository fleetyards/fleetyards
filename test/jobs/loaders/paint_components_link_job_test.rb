# frozen_string_literal: true

require "test_helper"

module Loaders
  class PaintComponentsLinkJobTest < ActiveSupport::TestCase
    test "#perform links the paints" do
      PaintComponentLinker.any_instance.expects(:run)

      ::Loaders::PaintComponentsLinkJob.new.perform
    end

    test "#perform goes back on the queue while another run holds the lock" do
      ActiveRecord::Base.stubs(:with_advisory_lock_result)
        .returns(WithAdvisoryLock::Result.new(lock_was_acquired: false))
      PaintComponentLinker.any_instance.expects(:run).never

      assert_difference -> { ::Loaders::PaintComponentsLinkJob.jobs.size }, 1 do
        ::Loaders::PaintComponentsLinkJob.new.perform
      end
      assert ::Loaders::PaintComponentsLinkJob.jobs.last["at"] > Time.current.to_f
    end
  end
end
