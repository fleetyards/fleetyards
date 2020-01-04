# frozen_string_literal: true

require 'test_helper'
require 'rsi/models_loader'

class RsiModelsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ::RSI::ModelsLoader.new }

  before do
    Timecop.freeze('2017-01-01 14:00:00')
  end

  after do
    Timecop.return
  end

  test '#all' do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.all

      expectations = {
        hardpoints: 2170,
        components: 122,
        models: 144,
        manufacturers: 45
      }

      assert_equal(expectations,
                   hardpoints: Hardpoint.count,
                   components: Component.count,
                   models: Model.count,
                   manufacturers: Manufacturer.count)

      assert_equal(Model.find_by(slug: '300i').rsi_chassis_id, Model.find_by(slug: '315p').rsi_chassis_id)
    end
  end

  test '#updates only when needed' do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.one(7)

      model = Model.find_by(name: '300i')

      Timecop.travel(1.day)

      loader.one(model.rsi_id)
      model.reload

      assert(model.updated_at.day != Time.zone.now.day)
      assert_equal(27.0, model.length.to_f)
    end
  end

  test '#updates production status only when time_modified changes' do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.one(7)

      model = Model.find_by(name: '300i')

      assert_equal('flight-ready', model.production_status)

      model.update(production_status: 'in-concept')

      Timecop.travel(1.day)

      loader.one(model.rsi_id)
      model.reload

      assert_equal('in-concept', model.production_status)
    end
  end

  test '#overides present data' do
    VCR.use_cassette('rsi_models_loader_all') do
      model_polaris = Model.create(
        name: 'Polaris',
        rsi_id: 116,
        length: 20.0
      )

      assert_equal(20.0, model_polaris.length.to_f)
      assert_equal(model_polaris.last_updated_at.utc.iso8601, model_polaris.created_at.utc.iso8601)

      Timecop.travel(1.day)

      loader.one(116)

      model_polaris.reload

      assert_equal(155.0, model_polaris.length.to_f)
      assert_equal('2017-10-24T12:38:57Z', model_polaris.last_updated_at.utc.iso8601)
    end
  end
end
