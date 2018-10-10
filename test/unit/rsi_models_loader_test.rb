# frozen_string_literal: true

require 'test_helper'
require 'rsi_models_loader'

class RsiModelsLoaderTest < ActiveSupport::TestCase
  let(:loader) { RsiModelsLoader.new }

  before do
    Timecop.freeze('2018-01-01 14:00:00')
  end

  after do
    Timecop.return
  end

  test '#all' do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.all

      expectations = {
        hardpoints: 1987,
        components: 124,
        models: 129,
        manufacturers: 44
      }

      assert_equal(expectations,
                   hardpoints: Hardpoint.count,
                   components: Component.count,
                   models: Model.count,
                   manufacturers: Manufacturer.count)
    end
  end

  test '#updates only when needed' do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.one(7)

      model = Model.find_by(name: 'mustang-alpha-vindicator')

      Timecop.travel(1.day)

      loader.one(model.rsi_id)
      model.reload

      assert(model.updated_at.day != Time.zone.now.day)
      assert_equal(23.0, model.length.to_f)
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
      assert_equal(model_polaris.last_updated_at.iso8601, model_polaris.created_at.iso8601)

      Timecop.travel(1.day)

      loader.one(116)

      model_polaris.reload

      assert_equal(155.0, model_polaris.length.to_f)
      assert_equal('2017-10-24T14:38:57+02:00', model_polaris.last_updated_at.iso8601)
    end
  end
end
