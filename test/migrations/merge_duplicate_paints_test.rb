# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261104120000_merge_duplicate_paints.rb")

class MergeDuplicatePaintsTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, name: "Nomad")
    @old = create(:model_paint, model: @model, name: "Ice Break")
    @kept = create(:model_paint, model: @model, name: "IceBreak")
  end

  # Past `normalizes`, which strips the value of any write that goes through the
  # attribute, `update_columns` included.
  def store_raw_name(paint, name)
    ModelPaint.where(id: paint.id).update_all(["name = ?", name])
  end

  test "moves owners and pictures to the kept paint" do
    vehicle = create(:vehicle, model: @model)
    VehiclePaint.create!(vehicle:, model_paint: @old)
    vehicle.update_columns(picture_type: "ModelPaint", picture_id: @old.id, updated_at: 1.day.ago)

    MergeDuplicatePaints.new.up

    assert_not ModelPaint.exists?(@old.id)
    assert_equal [@kept.id], vehicle.reload.model_paint_ids
    assert_equal @kept.id, vehicle.picture_id
    assert_operator vehicle.updated_at, :>, 1.hour.ago
    assert_equal 1, @model.reload.model_paints_count
  end

  test "keeps one link for a vehicle owning both copies" do
    vehicle = create(:vehicle, model: @model)
    VehiclePaint.create!(vehicle:, model_paint: @old)
    VehiclePaint.create!(vehicle:, model_paint: @kept)

    MergeDuplicatePaints.new.up

    assert_equal [@kept.id], vehicle.reload.model_paint_ids
  end

  test "carries over the component and views only the old copy has" do
    component = create(:component, category: "paints", name: "Nomad IceBreak Livery")
    @old.update!(component:)
    @old.top_view.attach(io: StringIO.new("top"), filename: "top.png", content_type: "image/png")
    @old.store_image.attach(io: StringIO.new("old"), filename: "old.png", content_type: "image/png")
    @kept.store_image.attach(io: StringIO.new("kept"), filename: "kept.png", content_type: "image/png")

    MergeDuplicatePaints.new.up

    @kept = ModelPaint.find(@kept.id)
    assert_equal component.id, @kept.component_id
    assert_predicate @kept.top_view, :attached?
    assert_equal "kept.png", @kept.store_image.filename.to_s
  end

  test "renames a paint with no second copy and links its pledges" do
    caterpillar = create(:model, name: "Caterpillar")
    paint = create(:model_paint, model: caterpillar, name: "Ice Break")
    item = create(:hangar_pledge_item, name: "Caterpillar - IceBreak Paint")

    MergeDuplicatePaints.new.up

    assert_equal "IceBreak", paint.reload.name
    assert_equal "icebreak", paint.slug
    assert_equal [paint.id], item.reload.model_paints.pluck(:id)
  end

  test "merges a paint saved with stray whitespace into its clean copy" do
    hammerhead = create(:model, name: "Hammerhead")
    clean = create(:model_paint, model: hammerhead, name: "Stormbringer")
    untrimmed = create(:model_paint, model: hammerhead, name: "Stormbringer")
    store_raw_name(untrimmed, " Stormbringer ")
    vehicle = create(:vehicle, model: hammerhead)
    VehiclePaint.create!(vehicle:, model_paint: untrimmed)

    MergeDuplicatePaints.new.up

    assert_not ModelPaint.exists?(untrimmed.id)
    assert_equal [clean.id], vehicle.reload.model_paint_ids
  end

  test "keeps the visible copy when the clean one is hidden" do
    hammerhead = create(:model, name: "Hammerhead")
    component = create(:component, category: "paints", name: "Hammerhead Stormbringer Livery")
    hidden = create(:model_paint, model: hammerhead, name: "Stormbringer", hidden: true, component:)
    visible = create(:model_paint, model: hammerhead, name: "Stormbringer", hidden: false)
    store_raw_name(visible, " Stormbringer ")
    vehicle = create(:vehicle, model: hammerhead)
    VehiclePaint.create!(vehicle:, model_paint: visible)
    item = create(:hangar_pledge_item, name: "Hammerhead - Stormbringer Paint")
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: hidden)

    MergeDuplicatePaints.new.up

    assert_not ModelPaint.exists?(hidden.id)
    assert_equal "Stormbringer", visible.reload.name
    assert_not visible.hidden
    assert_equal component.id, visible.component_id
    assert_equal [visible.id], vehicle.reload.model_paint_ids
    assert_equal [visible.id], item.reload.model_paints.pluck(:id)
  end

  test "renames a misspelt paint that also has stray whitespace" do
    paint = create(:model_paint, model: @model, name: "Ice Break")
    store_raw_name(paint, " Ice Break\u00A0")
    @old.destroy!

    MergeDuplicatePaints.new.up

    assert_not ModelPaint.exists?(paint.id)
    assert_equal ["IceBreak"], @model.reload.paints.pluck(:name)
  end

  test "touches the kept paint so its cached payload refreshes" do
    @kept.update_columns(updated_at: 1.day.ago)

    MergeDuplicatePaints.new.up

    assert_operator @kept.reload.updated_at, :>, 1.hour.ago
  end

  test "trims a paint with stray whitespace and no clean copy" do
    explorer = create(:model, name: "600i Explorer")
    tabbed = create(:model_paint, model: explorer, name: "Foundation Festival")
    store_raw_name(tabbed, "Foundation Festival\t")

    MergeDuplicatePaints.new.up

    assert_equal ["Foundation Festival"], ModelPaint.where(id: tabbed.id).pluck(Arel.sql("name"))
  end

  test "leaves other paints alone" do
    other = create(:model_paint, model: @model, name: "Deck the Hull")

    assert_no_changes -> { other.reload.attributes } do
      MergeDuplicatePaints.new.up
    end
  end
end
