# frozen_string_literal: true

require "test_helper"

module Cleanup
  class VisitsJobTest < ActiveJob::TestCase
    test "#perform runs rollup and deletes old visits and events" do
      tracking_blocklist = [SecureRandom.uuid]
      User.stubs(:where).with(tracking: false).returns(stub(pluck: tracking_blocklist))

      visit_scope = mock("visit_scope")
      visit_scope.expects(:rollup).with("Visits", interval: "month", column: :started_at)
      Ahoy::Visit.stubs(:without_users).with(tracking_blocklist).returns(visit_scope)

      Ahoy::Visit.stubs(:where).returns(stub(find_in_batches: nil))

      ::Cleanup::VisitsJob.new.perform
    end
  end
end
