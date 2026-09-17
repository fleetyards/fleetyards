# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class SyncJobTest < ActiveSupport::TestCase
    test "it reconciles and reports what it did" do
      membership = create(:fleet_membership, :accepted)
      create(:supporter_contribution, user: membership.user, fleet: membership.fleet,
        amount_cents: Subscriptions.qualifying_amount_cents)

      stats = SyncJob.new.perform

      assert_equal 1, stats[:opened].size
      assert membership.fleet.fleet_subscriptions.sole.open?
    end

    test "a run with nothing to do is not an error" do
      assert_nothing_raised { SyncJob.new.perform }
    end
  end
end
