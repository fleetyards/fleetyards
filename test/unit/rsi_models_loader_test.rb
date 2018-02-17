# frozen_string_literal: true

require 'test_helper'
require 'rsi_models_loader'

class RsiModelsLoaderTest < ActiveSupport::TestCase
  let(:loader) { RsiModelsLoader.new }

  test "#all" do
    VCR.use_cassette('rsi_models_loader_all') do
      loader.all

      expectations = {
        hardpoints: 1698,
        components: 111,
        models: 109,
        manufacturers: 42
      }

      assert_equal(expectations,
                   hardpoints: Hardpoint.count,
                   components: Component.count,
                   models: Model.count,
                   manufacturers: Manufacturer.count)
    end
  end

  test "#updates only when needed" do
    VCR.use_cassette('rsi_models_loader_all') do
      Timecop.freeze(Time.zone.now) do
        loader.one('300i')

        model = Model.find_by(name: '300i')

        Timecop.travel(1.day)

        loader.one(model.name)
        model.reload

        assert(model.updated_at.day != Time.zone.now.day)
        assert_equal(23.0, model.length.to_f)
      end
    end
  end

  test "#overides present data" do
    VCR.use_cassette('rsi_models_loader_all') do
      Timecop.freeze(Time.zone.now) do
        model_600i = Model.find_by(slug: '600i')

        assert_equal(20.0, model_600i.length.to_f)

        loader.one('600i Explorer')

        assert_equal(91.5, model_600i.reload.length.to_f)
      end
    end
  end
end
