# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ModelsJob do
  describe "#perform" do
    it "creates an import, runs the loader, and finishes the import" do
      loader = instance_double(Rsi::ModelsLoader)
      allow(Rsi::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:all)

      described_class.new.perform

      import = Imports::ModelsImport.last

      expect(import).to be_present
      expect(import.aasm_state).to eq("finished")
      expect(loader).to have_received(:all)
    end

    it "marks import as failed on error" do
      loader = instance_double(Rsi::ModelsLoader)
      allow(Rsi::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:all).and_raise(StandardError, "loader error")

      expect { described_class.new.perform }.to raise_error(StandardError, "loader error")

      import = Imports::ModelsImport.last

      expect(import.aasm_state).to eq("failed")
      expect(import.info).to eq("loader error")
    end
  end
end
