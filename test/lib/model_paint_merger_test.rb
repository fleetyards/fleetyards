# frozen_string_literal: true

require "test_helper"

class ModelPaintMergerTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, name: "Asgard")
    @kept = create(:model_paint, model: @model, name: "Skullcrusher")
    @duplicate = create(:model_paint, model: @model, name: "Skullcusher")
  end

  def merge
    ModelPaintMerger.new(@kept, @duplicate).run
  end

  test "moves owners, pictures and plan candidates to the kept paint" do
    vehicle = create(:vehicle, model: @model)
    VehiclePaint.create!(vehicle:, model_paint: @duplicate)
    vehicle.update_columns(picture_type: "ModelPaint", picture_id: @duplicate.id)
    candidate = create(:hangar_plan_candidate, model: @model, model_paint: @duplicate)

    assert_equal [vehicle.id], merge

    assert_not ModelPaint.exists?(@duplicate.id)
    assert_equal [@kept.id], vehicle.reload.model_paint_ids
    assert_equal @kept.id, vehicle.picture_id
    assert_equal @kept.id, candidate.reload.model_paint_id
    assert_equal 1, @model.reload.model_paints_count
  end

  test "keeps one link for a ship or pledge on both copies" do
    vehicle = create(:vehicle, model: @model)
    VehiclePaint.create!(vehicle:, model_paint: @duplicate)
    VehiclePaint.create!(vehicle:, model_paint: @kept)
    item = create(:hangar_pledge_item, name: "Asgard - Skullcrusher Paint")
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: @duplicate)
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: @kept)

    merge

    assert_equal [@kept.id], vehicle.reload.model_paint_ids
    assert_equal [@kept.id], item.reload.model_paints.pluck(:id)
  end

  test "moves prices" do
    price = create(:item_price, item: @duplicate)

    merge

    assert_equal @kept, price.reload.item
  end

  test "fills in what only the duplicate has, without overwriting the kept paint" do
    component = create(:component, category: "paints", name: "Asgard Skullcrusher Livery")
    @duplicate.update!(component:, rsi_id: 202, description: "theirs", store_url: "https://example.com/theirs")
    @kept.update!(description: "ours")
    @duplicate.top_view.attach(io: StringIO.new("top"), filename: "top.png", content_type: "image/png")
    @duplicate.store_image.attach(io: StringIO.new("old"), filename: "old.png", content_type: "image/png")
    @kept.store_image.attach(io: StringIO.new("kept"), filename: "kept.png", content_type: "image/png")

    merge

    @kept = ModelPaint.find(@kept.id)
    assert_equal component.id, @kept.component_id
    assert_equal 202, @kept.rsi_id
    assert_equal "ours", @kept.description
    assert_equal "https://example.com/theirs", @kept.store_url
    assert_predicate @kept.top_view, :attached?
    assert_equal "kept.png", @kept.store_image.filename.to_s
  end

  test "keeps the paint in the catalogue when the duplicate was" do
    @kept.update!(hidden: true, active: false)
    @duplicate.update!(hidden: false, active: true)

    merge

    assert_not @kept.reload.hidden
    assert @kept.active
  end

  test "refuses two store records" do
    @kept.update!(rsi_id: 202)
    @duplicate.update!(rsi_id: 203)

    assert_raises(ArgumentError) { ModelPaintMerger.new(@kept, @duplicate) }
  end

  test "refuses paints of two different ships" do
    other = create(:model_paint, name: "Skullcrusher")

    assert_raises(ArgumentError) { ModelPaintMerger.new(@kept, other) }
  end
end
