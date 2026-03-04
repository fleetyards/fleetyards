# frozen_string_literal: true

require "rails_helper"

RSpec.describe VehicleMailer do
  describe "#on_sale" do
    let(:vehicle) { create(:vehicle) }
    let(:mail) { described_class.on_sale(vehicle) }

    it "renders the subject with model name" do
      expect(mail.subject).to eq(I18n.t(:"mailer.vehicle.on_sale.subject", model: vehicle.model.name))
    end

    it "sends to the vehicle owner" do
      expect(mail.to).to eq([vehicle.user.email])
    end

    it "sets the broadcast message stream" do
      expect(mail["message_stream"].value).to eq("broadcast")
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
