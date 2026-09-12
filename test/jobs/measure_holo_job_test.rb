# frozen_string_literal: true

require "test_helper"

class MeasureHoloJobTest < ActiveJob::TestCase
  def attach(model, name, fixture)
    model.send(name).attach(
      io: File.open(Rails.root.join("test/fixtures/holo/#{fixture}")),
      filename: fixture
    )
    model
  end

  # The fixture box is 2 x 1 x 6, so sorted it is 6 / 2 / 1.
  test "#perform writes a holo's box to the columns it describes" do
    model = attach(create(:model), :holo, "plain.gltf")

    MeasureHoloJob.new.perform(model.id, "holo")
    model.reload

    assert_in_delta 6.0, model.length.to_f
    assert_in_delta 2.0, model.beam.to_f
    assert_in_delta 1.0, model.height.to_f
  end

  # The point of the separate columns: a landed holo describes the landed state
  # and must not overwrite the flying one.
  test "#perform keeps the landed columns apart from the flying ones" do
    model = create(:model, length: 99.0, beam: 98.0, height: 97.0)
    attach(model, :landed_holo, "plain.gltf")

    MeasureHoloJob.new.perform(model.id, "landed_holo")
    model.reload

    assert_in_delta 6.0, model.landed_length.to_f
    assert_in_delta 99.0, model.length.to_f
  end

  test "#perform reads a binary GLB" do
    model = attach(create(:model), :holo, "plain.glb")

    MeasureHoloJob.new.perform(model.id, "holo")

    assert_in_delta 6.0, model.reload.length.to_f
  end

  # A rotation off the axes bounds the rotated box rather than the hull, so the
  # numbers would be an upper bound presented as a measurement.
  test "#perform records nothing when the box is only an upper bound" do
    model = create(:model, length: 42.0)
    attach(model, :holo, "skewed.gltf")

    MeasureHoloJob.new.perform(model.id, "holo")

    assert_in_delta 42.0, model.reload.length.to_f
  end

  test "#perform survives a file with no bounds at all" do
    model = create(:model, length: 42.0)
    attach(model, :holo, "no_bounds.gltf")

    assert_nothing_raised { MeasureHoloJob.new.perform(model.id, "holo") }
    assert_in_delta 42.0, model.reload.length.to_f
  end

  test "#perform ignores an attachment it has no columns for" do
    model = create(:model, length: 42.0)

    assert_nothing_raised { MeasureHoloJob.new.perform(model.id, "store_image") }
    assert_in_delta 42.0, model.reload.length.to_f
  end

  test "#perform ignores a model that is gone" do
    assert_nothing_raised { MeasureHoloJob.new.perform(SecureRandom.uuid, "holo") }
  end
end
