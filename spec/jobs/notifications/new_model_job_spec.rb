# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::NewModelJob do
  describe "#perform" do
    it "sends discord notification and marks model as notified" do
      model = create(:model, notified: false)
      allow(Discord::NewShip).to receive(:new).and_return(double(run: true))

      described_class.new.perform(model.id)

      expect(Discord::NewShip).to have_received(:new).with(model: model)
      expect(model.reload.notified).to be(true)
    end
  end
end
