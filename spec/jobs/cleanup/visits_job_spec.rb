# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cleanup::VisitsJob do
  describe "#perform" do
    it "runs rollup and deletes old visits and events" do
      tracking_blocklist = [SecureRandom.uuid]
      allow(User).to receive(:where).with(tracking: false).and_return(double(pluck: tracking_blocklist))

      visit_scope = double("visit_scope")
      allow(Ahoy::Visit).to receive(:without_users).with(tracking_blocklist).and_return(visit_scope)
      allow(visit_scope).to receive(:rollup)

      allow(Ahoy::Visit).to receive(:where).and_return(double(find_in_batches: nil))

      described_class.new.perform

      expect(visit_scope).to have_received(:rollup).with("Visits", interval: "month", column: :started_at)
    end
  end
end
