# frozen_string_literal: true

require 'test_helper'
require 'rsi_models_loader'

class RsiModelsLoaderTest < ActiveSupport::TestCase
  let(:loader) { RsiModelsLoader.new }

  test "#all" do
    VCR.use_cassette('rsi_models_loader_all', record: :new_episodes) do
      loader.all

      expectations = {
        hardpoints: 0,
        components: 0,
        component_categories: 0,
        models: 108,
        manufacturers: 16
      }

      assert_equal(expectations,
                   hardpoints: Hardpoint.count,
                   components: Component.count,
                   component_categories: ComponentCategory.count,
                   models: Model.count,
                   manufacturers: Manufacturer.count)
    end
  end

  test "#updates only when needed" do
    VCR.use_cassette('rsi_models_loader_all', record: :new_episodes) do
      Timecop.freeze(Time.zone.now) do
        loader.one('Constellation Andromeda')

        model = Model.find_by(name: 'Constellation Andromeda')

        Timecop.travel(1.day)

        loader.one(model.name)
        model.reload

        assert(model.updated_at.day != Time.zone.now.day)
        assert_equal(61.0, model.length.to_f)
      end
    end
  end
end
