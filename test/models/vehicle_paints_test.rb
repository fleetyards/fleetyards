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
    assert @vehicle.update(model_paint_picture: @paint)
  end

  test "takes no paint of another model as its picture" do
    assert_not @vehicle.update(model_paint_picture: create(:model_paint, :with_store_image))
  end

  test "takes no paint without a store image as its picture" do
    assert_not @vehicle.update(model_paint_picture: create(:model_paint, model: @model))
  end

  test "a paint picture replaces a gallery image, and a gallery image a paint picture" do
    image = create(:image, gallery: @model)
    @vehicle.update!(model_image: image)

    @vehicle.update!(model_paint_picture: @paint)
    assert_nil @vehicle.reload.model_image_id

    @vehicle.update!(model_image: image)
    assert_nil @vehicle.reload.model_paint_picture_id
  end

  test "drops the paint picture on a model change" do
    @vehicle.update!(model_paint_picture: @paint)

    @vehicle.update!(model: create(:model))

    assert_nil @vehicle.reload.model_paint_picture_id
  end
end
