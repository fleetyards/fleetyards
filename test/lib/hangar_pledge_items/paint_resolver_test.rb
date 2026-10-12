# frozen_string_literal: true

require "test_helper"

class HangarPledgeItems::PaintResolverTest < ActiveSupport::TestCase
  def resolve(name)
    HangarPledgeItems::PaintResolver.new.model_paint_ids(name).sort
  end

  test "resolves a ship and paint pledge to that ship's paint" do
    model = create(:model, name: "Nomad")
    paint = create(:model_paint, model:, name: "Ice Break")

    assert_equal [paint.id], resolve("Nomad IceBreak Livery")
  end

  test "resolves a series pledge to the paint on every model of the series" do
    paints = %w[100i 125a 135c].map do |name|
      create(:model_paint, model: create(:model, name:), name: "Ice Break")
    end

    assert_equal paints.map(&:id).sort, resolve("100 Series IceBreak Livery")
  end

  test "resolves a pledge naming a ship and a paint with a separator" do
    model = create(:model, name: "C1 Spirit")
    paint = create(:model_paint, model:, name: "Deck the Hull")

    assert_includes resolve("Spirit - Deck the Hull Paint"), paint.id
  end

  test "resolves nothing for a paint the catalogue does not have" do
    create(:model, name: "Nomad")

    assert_empty resolve("Nomad IceBreak Livery")
  end
end
