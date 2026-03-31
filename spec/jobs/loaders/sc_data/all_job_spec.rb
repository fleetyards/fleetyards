# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ScData::AllJob do
  describe "#perform" do
    before do
      allow(Rails.configuration).to receive(:sc_data).and_return({version: "3.24.0"})
    end

    it "creates an import, runs the loader, and finishes the import" do
      allow(ScData::Loader::BaseLoader).to receive(:all)

      described_class.new.perform

      import = Imports::ScData::AllImport.last

      expect(import).to be_present
      expect(import.aasm_state).to eq("finished")
      expect(ScData::Loader::BaseLoader).to have_received(:all)
    end

    it "marks import as failed on error" do
      allow(ScData::Loader::BaseLoader).to receive(:all).and_raise(StandardError, "sc data error")

      expect { described_class.new.perform }.to raise_error(StandardError, "sc data error")

      import = Imports::ScData::AllImport.last

      expect(import.aasm_state).to eq("failed")
      expect(import.info).to eq("sc data error")
    end
  end
end
