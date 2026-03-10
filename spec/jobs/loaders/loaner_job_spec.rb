# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::LoanerJob do
  describe "#perform" do
    let(:loader) { instance_double(Rsi::LoanerLoader) }

    before do
      allow(Rsi::LoanerLoader).to receive(:new).and_return(loader)
      allow(ModelLoaner).to receive(:pluck).and_return([])
    end

    it "runs the loaner loader and cleans up orphaned loaners" do
      allow(loader).to receive(:run).and_return([[], []])

      described_class.new.perform

      expect(loader).to have_received(:run)
    end

    it "sends admin email when there are missing loaners" do
      allow(loader).to receive(:run).and_return([["Missing Loaner"], []])

      mailer = double(deliver_later: true)
      allow(AdminMailer).to receive(:missing_loaners).and_return(mailer)

      described_class.new.perform

      expect(AdminMailer).to have_received(:missing_loaners).with(["Missing Loaner"], [])
    end
  end
end
