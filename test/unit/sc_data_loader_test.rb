# frozen_string_literal: true

require 'test_helper'

class ScDataLoaderTest < ActiveSupport::TestCase
  let(:loader) { ::ScData::ShipsLoader.new }

  before do
    Timecop.freeze('2017-01-01 14:00:00')
  end

  after do
    Timecop.return
  end

  describe '#one' do
    let(:constellation_rsi_id) { 45 }
    let(:constellation_sc_data_id) { 'rsi_constellation_andromeda' }
    let(:model) { Model.find_by(rsi_id: constellation_rsi_id) }

    before do
      VCR.use_cassette('rsi_models_loader_all') do
        ::Rsi::ModelsLoader.new.one(constellation_rsi_id)
      end

      model.update(sc_identifier: constellation_sc_data_id)
    end

    test 'it loads data from game files' do
      VCR.use_cassette('sc_data_loader_one', allow_playback_repeats: true) do
        loader.load(model)

        assert_equal(96, ModelHardpoint.where(model_id: model.id).count)
        assert_equal(13, Component.count)
        assert_equal(0, ModelHardpoint.where(model_id: model.id, source: :game_files).deleted.count)
        assert_equal(39, ModelHardpoint.where(model_id: model.id, source: :ship_matrix).deleted.count)
      end
    end
  end
end
