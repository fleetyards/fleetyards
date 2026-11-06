# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261106120000_relink_ironclad_paint_pledges.rb")

class RelinkIroncladPaintPledgesTest < ActiveSupport::TestCase
  test "links an Ironclad paint pledge to the Ironclad Assault's paint" do
    ironclad_paint = create(:model_paint, model: create(:model, name: "Ironclad"), name: "Aquamarine")
    assault_paint = create(:model_paint, model: create(:model, name: "Ironclad Assault"), name: "Aquamarine")
    pledge = create(:hangar_pledge_item, kind: "paint", name: "Ironclad - Aquamarine Paint")
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: pledge, model_paint: ironclad_paint)

    RelinkIroncladPaintPledges.new.up

    linked = HangarPledgeItemModelPaint.where(hangar_pledge_item: pledge).pluck(:model_paint_id)

    assert_equal [ironclad_paint.id, assault_paint.id].sort, linked.sort
  end
end
