# frozen_string_literal: true

require "test_helper"

module ScData
  class ModelsLoaderTest < ActiveSupport::TestCase
    let(:loader) { ::ScData::Loader::ModelsLoader.new }

    describe "#one" do
      let(:constellation_sc_data_id) { "rsi_constellation_andromeda" }
      let(:model) { models :andromeda }

      before do
        model.update(sc_identifier: constellation_sc_data_id)
      end

      it "loads data from game files" do
        assert_difference(-> { Hardpoint.where(parent: model).count }, 95) do
          loader.one(model)
        end
      end
    end
  end
end
