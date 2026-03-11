# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScData::Loader::ModelsLoader do
  fixtures :models

  let(:loader) { described_class.new }

  describe "#one" do
    let(:constellation_sc_data_id) { "rsi_constellation_andromeda" }
    let(:model) { models(:andromeda) }

    before do
      model.update(sc_identifier: constellation_sc_data_id)
    end

    it "loads data from game files" do
      expect { loader.one(model) }.to change { Hardpoint.where(parent: model).count }.by(95)
    end
  end
end
