# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataMigrate::PurchasedToWantedJob do
  describe "#perform" do
    before do
      RSpec::Mocks.configuration.verify_partial_doubles = false
    end

    after do
      RSpec::Mocks.configuration.verify_partial_doubles = true
    end

    it "sets wanted based on the inverse of purchased?" do
      vehicle = double("Vehicle", purchased?: false)
      allow(Vehicle).to receive(:find).and_return(vehicle)
      allow(vehicle).to receive(:update).with(wanted: true).and_return(true)

      described_class.new.perform("some-uuid")

      expect(vehicle).to have_received(:update).with(wanted: true)
    end

    it "sets wanted to false when vehicle is purchased" do
      vehicle = double("Vehicle", purchased?: true)
      allow(Vehicle).to receive(:find).and_return(vehicle)
      allow(vehicle).to receive(:update).with(wanted: false).and_return(true)

      described_class.new.perform("some-uuid")

      expect(vehicle).to have_received(:update).with(wanted: false)
    end
  end
end
