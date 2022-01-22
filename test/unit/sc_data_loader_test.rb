# frozen_string_literal: true

require 'test_helper'

class ScDataLoaderTest < ActiveSupport::TestCase
  setup do
    Timecop.freeze('2017-01-01 14:00:00')

    @constellation_rsi_id = 45

    VCR.use_cassette('rsi_models_loader_all') do
      ::Rsi::ModelsLoader.new.one(@constellation_rsi_id)
    end
  end

  teardown do
    Timecop.return
  end

  test 'it loads data from game files' do
    model = Model.find_by(rsi_id: @constellation_rsi_id)
    model.update(sc_identifier: 'rsi_constellation_andromeda')

    VCR.use_cassette('sc_data_loader_one') do
      ::ScData::ShipsLoader.new.load(model)

      assert_equal(95, ModelHardpoint.where(model_id: model.id).count)
      assert_equal(25, Component.count)
      assert_equal(0, ModelHardpoint.where(model_id: model.id, source: :game_files).deleted.count)
      assert_equal(39, ModelHardpoint.where(model_id: model.id, source: :ship_matrix).deleted.count)
    end
  end
end
