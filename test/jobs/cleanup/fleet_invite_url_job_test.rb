# frozen_string_literal: true

require "test_helper"

module Cleanup
  class FleetInviteUrlJobTest < ActiveJob::TestCase
    test "#perform destroys expired invite urls" do
      invite_url = create(:fleet_invite_url, expires_after: 1.day.ago)

      ::Cleanup::FleetInviteUrlJob.new.perform

      refute FleetInviteUrl.exists?(invite_url.id)
    end

    test "#perform destroys invite urls with limit of zero" do
      invite_url = create(:fleet_invite_url, limit: 0)

      ::Cleanup::FleetInviteUrlJob.new.perform

      refute FleetInviteUrl.exists?(invite_url.id)
    end

    test "#perform keeps valid invite urls" do
      invite_url = create(:fleet_invite_url, expires_after: 1.day.from_now, limit: 10)

      ::Cleanup::FleetInviteUrlJob.new.perform

      assert FleetInviteUrl.exists?(invite_url.id)
    end

    test "#perform keeps invite urls without expiry or limit" do
      invite_url = create(:fleet_invite_url)

      ::Cleanup::FleetInviteUrlJob.new.perform

      assert FleetInviteUrl.exists?(invite_url.id)
    end
  end
end
