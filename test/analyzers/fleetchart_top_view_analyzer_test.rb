# frozen_string_literal: true

require "test_helper"
require "vips"

class FleetchartTopViewAnalyzerTest < ActiveSupport::TestCase
  # A transparent picture holding one opaque rectangle.
  def picture(width, height, left, top, box_width, box_height)
    alpha = ::Vips::Image.black(width, height).draw_rect(255, left, top, box_width, box_height, fill: true)
    image = ::Vips::Image.black(width, height, bands: 3).bandjoin(alpha).cast(:uchar).copy(interpretation: :srgb)

    StringIO.new(image.write_to_buffer(".png"))
  end

  def attach(model, name, io)
    model.public_send(name).attach(io:, filename: "#{name}.png", content_type: "image/png")
    model.public_send(name).blob.tap(&:analyze).metadata
  end

  test "measures how wide the angled pictures are from the outline" do
    metadata = attach(create(:model), :top_view, picture(400, 400, 0, 0, 400, 400))

    assert_in_delta 1.414, metadata[:angled_extent], 0.01
    assert_in_delta 1.405, metadata[:angled_rear_extent], 0.01
    assert_equal 400, metadata[:width]
  end

  test "a thin ship is as wide as its length at that angle, and its own thickness" do
    metadata = attach(create(:model), :top_view, picture(400, 40, 0, 15, 400, 10))

    assert_in_delta 0.725, metadata[:angled_extent], 0.01
  end

  test "the backfill measures the top views already there, and only those" do
    require Rails.root.join("db/data/20261104200000_measure_fleetchart_top_views").to_s

    model = create(:model)

    model.top_view.attach(io: picture(100, 100, 0, 0, 100, 100), filename: "top.png", content_type: "image/png")
    model.port_view.attach(io: picture(100, 100, 0, 0, 100, 100), filename: "port.png", content_type: "image/png")

    analyzed = []
    job = ActiveStorage::AnalyzeJob
    original = job.method(:perform_later)

    job.define_singleton_method(:perform_later) { |blob| analyzed << blob }
    MeasureFleetchartTopViews.new.up
    job.define_singleton_method(:perform_later, original)

    assert_equal [model.top_view.blob], analyzed
  end

  test "measures a module package's top view, which holds its modules beside the ship" do
    metadata = attach(create(:model_module_package), :top_view, picture(400, 400, 0, 0, 400, 400))

    assert_in_delta 1.414, metadata[:angled_extent], 0.01
  end

  test "leaves a module package's other pictures alone" do
    metadata = attach(create(:model_module_package), :angled_view, picture(100, 100, 0, 0, 100, 100))

    assert_not metadata.key?(:angled_extent)
  end

  test "the package backfill measures the package top views already there, and only those" do
    require Rails.root.join("db/data/20261110190000_measure_module_package_top_views").to_s

    package = create(:model_module_package)

    package.top_view.attach(io: picture(100, 100, 0, 0, 100, 100), filename: "top.png", content_type: "image/png")
    package.port_view.attach(io: picture(100, 100, 0, 0, 100, 100), filename: "port.png", content_type: "image/png")
    package.model.top_view.attach(io: picture(100, 100, 0, 0, 100, 100), filename: "model-top.png", content_type: "image/png")

    analyzed = []
    job = ActiveStorage::AnalyzeJob
    original = job.method(:perform_later)

    job.define_singleton_method(:perform_later) { |blob| analyzed << blob }
    MeasureModulePackageTopViews.new.up
    job.define_singleton_method(:perform_later, original)

    assert_equal [package.top_view.blob], analyzed
  end

  test "leaves other pictures alone" do
    model = create(:model)

    metadata = attach(model, :port_view, picture(100, 100, 0, 0, 100, 100))

    assert_equal 100, metadata[:width]
    assert_not metadata.key?(:angled_extent)
  end
end
