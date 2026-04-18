# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsCredsBackport::CombinedConfiguration do
  let(:backend_a) do
    instance_double(RailsCredsBackport::EnvConfiguration).tap do |b|
      allow(b).to receive(:option).and_return(nil)
      allow(b).to receive(:reload)
    end
  end

  let(:backend_b) do
    instance_double(RailsCredsBackport::EnvConfiguration).tap do |b|
      allow(b).to receive(:option).and_return(nil)
      allow(b).to receive(:reload)
    end
  end

  subject(:combined) { described_class.new(backend_a, backend_b) }

  describe "#require" do
    it "returns the value from the first backend that has it" do
      allow(backend_a).to receive(:option).with(:key).and_return("from_a")
      expect(combined.require(:key)).to eq("from_a")
    end

    it "falls through to the second backend" do
      allow(backend_a).to receive(:option).with(:key).and_return(nil)
      allow(backend_b).to receive(:option).with(:key).and_return("from_b")
      expect(combined.require(:key)).to eq("from_b")
    end

    it "raises KeyError when no backend has the key" do
      expect { combined.require(:missing) }.to raise_error(KeyError)
    end

    it "returns false values without raising" do
      allow(backend_a).to receive(:option).with(:flag).and_return(false)
      expect(combined.require(:flag)).to eq(false)
    end
  end

  describe "#option" do
    it "returns nil when no backend has the key" do
      expect(combined.option(:missing)).to be_nil
    end

    it "returns the default when no backend has the key" do
      expect(combined.option(:missing, default: "fallback")).to eq("fallback")
    end

    it "calls a default proc" do
      expect(combined.option(:missing, default: -> { "computed" })).to eq("computed")
    end

    it "returns false values without triggering default" do
      allow(backend_a).to receive(:option).with(:flag).and_return(false)
      expect(combined.option(:flag, default: "nope")).to eq(false)
    end
  end

  describe "#reload" do
    it "reloads all backends" do
      combined.reload
      expect(backend_a).to have_received(:reload)
      expect(backend_b).to have_received(:reload)
    end
  end
end
