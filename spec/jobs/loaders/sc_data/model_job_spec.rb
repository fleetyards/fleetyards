# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::ScData::ModelJob do
  describe "#perform" do
    it "creates an import, runs the loader, and finishes the import" do
      model = create(:model)
      loader = instance_double(ScData::Loader::ModelsLoader)
      allow(ScData::Loader::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:one)

      described_class.new.perform(model.id)

      import = Imports::ScData::ModelImport.last

      expect(import).to be_present
      expect(import.aasm_state).to eq("finished")
      expect(loader).to have_received(:one).with(model)
    end

    it "marks import as failed on error" do
      model = create(:model)
      loader = instance_double(ScData::Loader::ModelsLoader)
      allow(ScData::Loader::ModelsLoader).to receive(:new).and_return(loader)
      allow(loader).to receive(:one).and_raise(StandardError, "sc data error")

      expect { described_class.new.perform(model.id) }.to raise_error(StandardError, "sc data error")

      import = Imports::ScData::ModelImport.last

      expect(import.aasm_state).to eq("failed")
      expect(import.info).to eq("sc data error")
    end
  end
end
