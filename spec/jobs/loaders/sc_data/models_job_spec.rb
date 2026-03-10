# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ScData::ModelsJob do
  describe "#perform" do
    before do
      allow(Rails.configuration.app).to receive(:sc_data_sc_version).and_return("3.24.0")
    end

    it "creates an import, runs the loader, and finishes the import" do
      loader = instance_double(ScData::Loader::ModelsLoader)
      allow(ScData::Loader::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:all)

      described_class.new.perform

      import = Imports::ScData::ModelsImport.last

      expect(import).to be_present
      expect(import.aasm_state).to eq("finished")
      expect(loader).to have_received(:all)
    end

    it "marks import as failed on error" do
      loader = instance_double(ScData::Loader::ModelsLoader)
      allow(ScData::Loader::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:all).and_raise(StandardError, "sc data error")

      expect { described_class.new.perform }.to raise_error(StandardError, "sc data error")

      import = Imports::ScData::ModelsImport.last

      expect(import.aasm_state).to eq("failed")
      expect(import.info).to eq("sc data error")
    end
  end
end
