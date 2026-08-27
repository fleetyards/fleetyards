# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class PaintsImporterTest < ActiveSupport::TestCase
  IMAGE_URL = "https://robertsspaceindustries.com/media/paint.jpg"

  setup do
    stub_request(:get, IMAGE_URL)
      .to_return(status: 200, body: "image", headers: {"Content-Type" => "image/jpeg"})
  end

  def hangar_sync(*names)
    create(
      :import,
      :hangar_sync,
      input: names.map { |name| {"type" => "skin", "name" => name, "image" => IMAGE_URL} }
    )
  end

  test "#run imports a paint for every model the source name maps to" do
    aurora_cl = create(:model, name: "Aurora Mk I CL")
    aurora_es = create(:model, name: "Aurora Mk I ES")
    hangar_sync("Aurora Mk I - Dread Pirate Paint")

    PaintsImporter.new.run

    assert_equal ["Dread Pirate"], aurora_cl.paints.pluck(:name)
    assert_equal ["Dread Pirate"], aurora_es.paints.pluck(:name)
  end

  test "#run for a single model imports a series paint into the whole series" do
    aurora_cl = create(:model, name: "Aurora Mk I CL")
    aurora_es = create(:model, name: "Aurora Mk I ES")
    hangar_sync("Aurora Mk I - Dread Pirate Paint")

    results = PaintsImporter.new(model: aurora_cl).run

    assert_equal ["Dread Pirate"], aurora_cl.paints.pluck(:name)
    assert_equal ["Dread Pirate"], aurora_es.paints.pluck(:name)
    assert_equal 2, results[:new][:count]
  end

  test "#run for a single model skips paints belonging to other models" do
    arrow = create(:model, name: "Arrow")
    nomad = create(:model, name: "Nomad")
    hangar_sync("Nomad - Ice Break Paint", "Arrow - Twilight Paint")

    results = PaintsImporter.new(model: arrow).run

    assert_equal ["Twilight"], arrow.paints.pluck(:name)
    assert_empty nomad.paints
    assert_equal 0, results[:model_not_found][:count]
  end

  test "#run for a single model reports a paint it already has as existing" do
    arrow = create(:model, name: "Arrow")
    create(:model_paint, model: arrow, name: "Twilight")
    hangar_sync("Arrow - Twilight Paint")

    results = PaintsImporter.new(model: arrow).run

    assert_equal 1, results[:existing][:count]
    assert_equal 0, results[:new][:count]
    assert_equal ["Twilight"], arrow.paints.pluck(:name)
  end

  test "#run imports a series paint into the models that are still missing it" do
    aurora_cl = create(:model, name: "Aurora Mk I CL")
    aurora_es = create(:model, name: "Aurora Mk I ES")
    create(:model_paint, model: aurora_cl, name: "Dread Pirate")
    hangar_sync("Aurora Mk I - Dread Pirate Paint")

    results = PaintsImporter.new.run

    assert_equal ["Dread Pirate"], aurora_es.paints.pluck(:name)
    assert_equal 1, results[:new][:count]
    assert_equal 1, results[:existing][:count]
  end

  test "#run for a single model reports an unmapped source name as a missing model" do
    nova = create(:model, name: "Nova Tank")
    hangar_sync("Nova - Sandstorm Paint")

    results = PaintsImporter.new(model: nova).run

    assert_equal 1, results[:model_not_found][:count]
    assert_empty nova.paints
  end

  test "#run for a single model ignores unmapped source names of other models" do
    nova = create(:model, name: "Nova Tank")
    hangar_sync("Sunburst - Sandstorm Paint")

    results = PaintsImporter.new(model: nova).run

    assert_equal 0, results[:model_not_found][:count]
    assert_empty nova.paints
  end

  test "#run for a single model ignores a source name that resolves to another model" do
    nova_tank = create(:model, name: "Nova Tank")
    nova = create(:model, name: "Nova")
    hangar_sync("Nova - Sandstorm Paint")

    results = PaintsImporter.new(model: nova_tank).run

    assert_equal 0, results[:model_not_found][:count]
    assert_empty nova_tank.paints
    assert_empty nova.paints
  end
end
