# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::AppVersionJob do
  describe "#perform" do
    it "broadcasts app version via ActionCable" do
      allow(ActionCable.server).to receive(:broadcast)

      described_class.new.perform

      expect(ActionCable.server).to have_received(:broadcast).with(
        "app_version",
        {version: Fleetyards::VERSION, codename: Fleetyards::CODENAME}.to_json
      )
    end
  end
end
