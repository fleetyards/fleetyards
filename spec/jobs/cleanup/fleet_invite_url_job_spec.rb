# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cleanup::FleetInviteUrlJob do
  describe "#perform" do
    it "destroys expired invite urls" do
      invite_url = create(:fleet_invite_url, expires_after: 1.day.ago)

      described_class.new.perform

      expect(FleetInviteUrl.exists?(invite_url.id)).to be(false)
    end

    it "destroys invite urls with limit of zero" do
      invite_url = create(:fleet_invite_url, limit: 0)

      described_class.new.perform

      expect(FleetInviteUrl.exists?(invite_url.id)).to be(false)
    end

    it "keeps valid invite urls" do
      invite_url = create(:fleet_invite_url, expires_after: 1.day.from_now, limit: 10)

      described_class.new.perform

      expect(FleetInviteUrl.exists?(invite_url.id)).to be(true)
    end

    it "keeps invite urls without expiry or limit" do
      invite_url = create(:fleet_invite_url)

      described_class.new.perform

      expect(FleetInviteUrl.exists?(invite_url.id)).to be(true)
    end
  end
end
