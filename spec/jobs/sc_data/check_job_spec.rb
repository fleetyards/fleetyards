# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScData::CheckJob do
  describe "#perform" do
    before do
      allow(Loaders::ScData::AllJob).to receive(:perform_async)
    end

    it "enqueues AllJob when version is new" do
      allow(Rails.configuration).to receive(:sc_data).and_return({version: "3.24.0"})
      allow(Imports::ScData::AllImport).to receive_message_chain(:finished, :exists?).and_return(false)

      described_class.new.perform

      expect(Loaders::ScData::AllJob).to have_received(:perform_async).with("3.24.0")
    end

    it "does not enqueue AllJob when version is blank" do
      allow(Rails.configuration).to receive(:sc_data).and_return({version: nil})

      described_class.new.perform

      expect(Loaders::ScData::AllJob).not_to have_received(:perform_async)
    end

    it "does not enqueue AllJob when import already finished for version" do
      allow(Rails.configuration).to receive(:sc_data).and_return({version: "3.24.0"})
      allow(Imports::ScData::AllImport).to receive_message_chain(:finished, :exists?).and_return(true)

      described_class.new.perform

      expect(Loaders::ScData::AllJob).not_to have_received(:perform_async)
    end
  end
end
