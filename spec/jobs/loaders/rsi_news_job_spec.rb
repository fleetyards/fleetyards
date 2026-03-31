# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::RsiNewsJob do
  describe "#perform" do
    it "runs the news loader" do
      loader = instance_double(Rsi::NewsLoader)
      allow(Rsi::NewsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:update)

      described_class.new.perform

      expect(loader).to have_received(:update)
    end
  end
end
