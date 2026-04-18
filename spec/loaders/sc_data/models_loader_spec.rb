# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScData::Loader::ModelsLoader do
  let(:loader) { described_class.new }
  let(:manufacturer) { create(:manufacturer, name: "Roberts Space Industries", slug: "rsi", code: "RSI") }

  describe "#one" do
    let(:model) do
      create(:model,
        name: "Constellation Andromeda",
        manufacturer: manufacturer)
    end

    it "loads data from game files" do
      expect { loader.one(model) }.to change { Hardpoint.where(parent: model).count }.by(95)
    end
  end
end
