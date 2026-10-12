# frozen_string_literal: true

require "test_helper"

class HangarPledgeItems::PaintLinkerTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, name: "Nomad")
    @paint = create(:model_paint, model: @model, name: "Ice Break")
  end

  test "links a paint pledge to its catalogue paint" do
    item = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")

    HangarPledgeItems::PaintLinker.new.link([item])

    assert_equal [@paint], item.reload.model_paints.to_a
  end

  test "replaces links a pledge no longer resolves to" do
    item = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")
    stale = create(:model_paint, model: @model, name: "Stale")
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: stale)

    HangarPledgeItems::PaintLinker.new.link([item])

    assert_equal [@paint], item.reload.model_paints.to_a
  end

  test "leaves flair and equipment alone" do
    item = create(:hangar_pledge_item, kind: "flair", name: "Nomad IceBreak Livery")

    HangarPledgeItems::PaintLinker.new.link([item])

    assert_empty item.reload.model_paints
  end

  test "skips a pledge that went away after it was read" do
    item = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")
    melted = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")
    melted.delete

    HangarPledgeItems::PaintLinker.new.link([item, melted])

    assert_equal [@paint], item.reload.model_paints.to_a
    assert_equal 1, HangarPledgeItemModelPaint.count
  end

  test "skips a paint deleted after the catalogue was read" do
    item = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")
    resolver = HangarPledgeItems::PaintResolver.new
    resolver.model_paint_ids(item.name)
    @paint.delete

    HangarPledgeItems::PaintLinker.new(resolver:).link([item])

    assert_empty item.reload.model_paints
  end

  test "links every stored paint pledge" do
    items = create_list(:hangar_pledge_item, 2, name: "Nomad IceBreak Livery")

    HangarPledgeItems::PaintLinker.new.link_all

    items.each { |item| assert_equal [@paint], item.reload.model_paints.to_a }
  end
end
