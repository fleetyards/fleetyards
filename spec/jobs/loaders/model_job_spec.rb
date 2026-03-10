# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ModelJob do
  describe "#perform" do
    it "creates an import, runs the loader, and finishes the import" do
      loader = instance_double(Rsi::ModelsLoader)
      allow(Rsi::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:one)

      described_class.new.perform(123)

      import = Imports::ModelImport.last

      expect(import).to be_present
      expect(import.aasm_state).to eq("finished")
      expect(loader).to have_received(:one).with(123)
    end

    it "marks import as failed on error" do
      loader = instance_double(Rsi::ModelsLoader)
      allow(Rsi::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:one).and_raise(StandardError, "loader error")

      expect { described_class.new.perform(123) }.to raise_error(StandardError, "loader error")

      import = Imports::ModelImport.last

      expect(import.aasm_state).to eq("failed")
      expect(import.info).to eq("loader error")
    end
  end
end
