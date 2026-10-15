# frozen_string_literal: true

require "test_helper"

class VehiclePaintsTest < ActiveSupport::TestCase
  setup do
    @model = create(:model)
    @vehicle = create(:vehicle, model: @model)
    @paint = create(:model_paint, :with_store_image, model: @model)
  end

  test "owns several paints of its model" do
    other = create(:model_paint, model: @model)

    @vehicle.update!(model_paint_ids: [@paint.id, other.id])

    assert_equal [@paint.id, other.id].sort, @vehicle.reload.model_paint_ids.sort
  end

  test "keeps a paint's pledge when the owned list is written again" do
    @vehicle.vehicle_paints.create!(model_paint: @paint, rsi_pledge_id: "123")

    @vehicle.reload.update!(model_paint_ids: [@paint.id])

    assert_equal "123", @vehicle.vehicle_paints.sole.rsi_pledge_id
  end

  test "owns no paint of another model" do
    owned = @vehicle.vehicle_paints.build(model_paint: create(:model_paint))

    assert_not owned.valid?
  end

  test "drops the paints of the old model on a model change" do
    @vehicle.update!(model_paint_ids: [@paint.id])

    @vehicle.update!(model: create(:model))

    assert_empty @vehicle.reload.model_paint_ids
  end

  test "takes a paint of its model with a store image as its picture" do
    assert @vehicle.update(picture: @paint)
  end

  test "takes no paint of another model as its picture" do
    assert_not @vehicle.update(picture: create(:model_paint, :with_store_image))
  end

  test "takes a picture type only together with an id, and the other way round" do
    assert_not @vehicle.update(picture_type: "ModelPaint", picture_id: nil)
    assert_not @vehicle.reload.update(picture_type: nil, picture_id: @paint.id)
  end

  test "takes no paint without a store image as its picture" do
    assert_not @vehicle.update(picture: create(:model_paint, model: @model))
  end

  test "a deleted gallery image leaves the ship showing it touched, and without a picture" do
    image = create(:image, gallery: @model)
    @vehicle.update!(picture: image)
    @vehicle.update_columns(updated_at: 1.day.ago)

    image.destroy!

    @vehicle.reload
    assert_nil @vehicle.picture_id
    assert_operator @vehicle.updated_at, :>, 1.hour.ago
  end

  test "a deleted paint leaves the ships owning it, and the one showing it, touched" do
    @vehicle.update!(model_paint_ids: [@paint.id], picture: @paint)
    @vehicle.update_columns(updated_at: 1.day.ago)

    @paint.destroy!

    @vehicle.reload
    assert_empty @vehicle.model_paint_ids
    assert_nil @vehicle.picture_id
    assert_operator @vehicle.updated_at, :>, 1.hour.ago
  end

  test "drops the paint picture on a model change" do
    @vehicle.update!(picture: @paint)

    @vehicle.update!(model: create(:model))

    assert_nil @vehicle.reload.picture_id
  end
end
