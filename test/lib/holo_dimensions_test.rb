# frozen_string_literal: true

require "test_helper"

class HoloDimensionsTest < ActiveSupport::TestCase
  def fixture(name)
    Rails.root.join("test/fixtures/holo/#{name}.gltf")
  end

  test "reads the box straight off the accessor" do
    result = HoloDimensions.from_file(fixture("plain"))

    assert_in_delta 2.0, result.x
    assert_in_delta 1.0, result.y
    assert_in_delta 6.0, result.z
  end

  # The reason the transforms cannot be skipped: a Blender export puts its
  # rotation on the node, and the Pisces comes out with its length on x.
  test "applies a node rotation" do
    result = HoloDimensions.from_file(fixture("rotated"))

    assert_in_delta 6.0, result.x, 0.001
    assert_in_delta 1.0, result.y, 0.001
    assert_in_delta 2.0, result.z, 0.001
  end

  test "applies a node scale" do
    result = HoloDimensions.from_file(fixture("scaled"))

    assert_in_delta 4.0, result.x
    assert_in_delta 2.0, result.y
    assert_in_delta 12.0, result.z
  end

  # Two nodes sharing a mesh, one pushed along z: the box has to span both.
  test "unions every part of the scene" do
    result = HoloDimensions.from_file(fixture("two_parts"))

    assert_in_delta 2.0, result.x
    assert_in_delta 10.0, result.z
  end

  test "answers nothing when no accessor states its bounds" do
    assert_nil HoloDimensions.from_file(fixture("no_bounds"))
  end

  test "sorts largest first and states proportions against it" do
    result = HoloDimensions.from_file(fixture("plain"))

    assert_equal [6.0, 2.0, 1.0], result.sorted
    assert_equal [1.0, 0.3333, 0.1667], result.proportions
  end
end
