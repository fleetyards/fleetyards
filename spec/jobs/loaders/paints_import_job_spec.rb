# frozen_string_literal: true

require "rails_helper"

RSpec.describe Loaders::PaintsImportJob do
  describe "#perform" do
    it "runs the paints importer and sends results email" do
      importer = instance_double(PaintsImporter)
      allow(PaintsImporter).to receive(:new).and_return(importer)
      allow(importer).to receive(:run).and_return({imported: 5})

      mailer = double(deliver_later: true)
      allow(AdminMailer).to receive(:paints_import_results).and_return(mailer)

      described_class.new.perform

      expect(importer).to have_received(:run)
      expect(AdminMailer).to have_received(:paints_import_results).with({imported: 5})
    end
  end
end
