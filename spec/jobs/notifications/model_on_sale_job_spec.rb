# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::ModelOnSaleJob do
  describe "#perform" do
    let(:model) { create(:model, pledge_price: 100) }

    before do
      allow(Discord::ShipOnSale).to receive(:new).and_return(double(run: true))
    end

    it "sends discord notification when model has pledge price" do
      described_class.new.perform(model.id)

      expect(Discord::ShipOnSale).to have_received(:new).with(model: model)
    end

    it "does not send discord notification when pledge price is nil" do
      model.update_column(:pledge_price, nil)

      described_class.new.perform(model.id)

      expect(Discord::ShipOnSale).not_to have_received(:new)
    end

    it "notifies users with wanted vehicles that have sale_notify enabled" do
      user = create(:user, sale_notify: true)
      vehicle = create(:vehicle, model: model, user: user, sale_notify: true, wanted: true, loaner: false, notify: true)

      allow(OnSaleHangarChannel).to receive(:broadcast_to)
      mailer = double(deliver_later: true)
      allow(VehicleMailer).to receive(:on_sale).and_return(mailer)

      described_class.new.perform(model.id)

      expect(OnSaleHangarChannel).to have_received(:broadcast_to)
      expect(VehicleMailer).to have_received(:on_sale).with(vehicle)
    end
  end
end
