# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::AdminJob do
  describe "#perform" do
    it "sends weekly admin email with stats" do
      mailer = double(deliver_later: true)
      allow(AdminMailer).to receive(:weekly).and_return(mailer)

      described_class.new.perform

      expect(AdminMailer).to have_received(:weekly) do |stats|
        expect(stats).to include(:registrations, :ships, :vehicles, :wishes, :fleets)
      end
    end
  end
end
