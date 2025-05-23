# frozen_string_literal: true

require "test_helper"

class RsiModelsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ::Rsi::ModelsLoader.new }

  before do
    Timecop.freeze("2017-01-01 14:00:00")

    Model.destroy_all
    Component.destroy_all
    ModelPaint.destroy_all
    ModelHardpoint.destroy_all
    ModelModule.destroy_all
    ModelModulePackage.destroy_all
    ModelSnubCraft.destroy_all
    ModuleHardpoint.destroy_all
    Manufacturer.destroy_all
  end

  after do
    Timecop.return
  end

  test "#all" do
    VCR.use_cassette("rsi_models_loader_all") do
      loader.all

      expectations = {
        hardpoints: 7342,
        components: 14,
        models: 215,
        paints: 15,
        manufacturers: 18
      }

      assert_equal(expectations,
        hardpoints: ModelHardpoint.count,
        components: Component.count,
        models: Model.count,
        paints: ModelPaint.count,
        manufacturers: Manufacturer.count)

      assert_equal(Model.find_by(slug: "300i").rsi_chassis_id, Model.find_by(slug: "315p").rsi_chassis_id)
    end
  end

  test "#updates only when needed" do
    VCR.use_cassette("rsi_models_loader_300i") do
      loader.one(7)

      model = Model.find_by(name: "300i")

      Timecop.travel(1.day)

      loader.one(model.rsi_id)
      model.reload

      assert_not_equal(model.updated_at.day, Time.zone.now.day)
      assert_in_delta(27.0, model.length.to_f)
    end
  end

  test "#updates production status only when time_modified changes" do
    VCR.use_cassette("rsi_models_loader_300i") do
      loader.one(7)

      model = Model.find_by(name: "300i")

      assert_equal("flight-ready", model.production_status)

      model.update(production_status: "in-concept")

      Timecop.travel(1.day)

      loader.one(model.rsi_id)
      model.reload

      assert_equal("in-concept", model.production_status)
    end
  end

  test "#overides present data" do
    VCR.use_cassette("rsi_models_loader_polaris") do
      model_polaris = Model.create(
        name: "Polaris",
        rsi_id: 116,
        length: 20.0
      )

      assert_in_delta(20.0, model_polaris.length.to_f)
      assert_equal(model_polaris.last_updated_at.utc.iso8601, model_polaris.created_at.utc.iso8601)

      Timecop.travel(1.day)

      loader.one(116)

      model_polaris.reload

      assert_in_delta(166.0, model_polaris.length.to_f)
      assert_equal("2024-12-05T19:00:50Z", model_polaris.last_updated_at.utc.iso8601)
    end
  end

  test "#saves hardpoint data" do
    VCR.use_cassette("rsi_models_loader_300i") do
      loader.one(7)

      model = Model.find_by(name: "300i")

      assert_equal([
        34,
        0,
        0
      ], [
        ModelHardpoint.where(model_id: model.id).count,
        Component.count,
        ModelHardpoint.where(model_id: model.id).deleted.count
      ])
    end
  end
end
