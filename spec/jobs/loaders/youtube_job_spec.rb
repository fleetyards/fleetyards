# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::YoutubeJob do
  describe "#perform" do
    it "runs the youtube video loader" do
      loader = instance_double(Youtube::VideoLoader)
      allow(Youtube::VideoLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:update)

      described_class.new.perform

      expect(loader).to have_received(:update)
    end
  end
end
