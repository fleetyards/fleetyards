# frozen_string_literal: true

require 'test_helper'
require 'rsi_models_loader'

class RsiModelsLoaderTest < ActiveSupport::TestCase
  let(:loader) { RsiModelsLoader.new }

  test "#all" do
    VCR.use_cassette('rsi_models_loader_all', record: :new_episodes) do
      loader.all

      expectations = {
        hardpoints: 1698,
        components: 111,
        models: 110,
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
    VCR.use_cassette('rsi_models_loader_all', record: :new_episodes) do
      Timecop.freeze(Time.zone.now) do
        loader.one('300i')

        model = Model.find_by(name: '300i')

        Timecop.travel(1.day)

        loader.one(model.name)
        model.reload

        assert(model.updated_at.day != Time.zone.now.day)
        assert_equal(61.0, model.length.to_f)
      end
    end
  end
end
