# frozen_string_literal: true

require "test_helper"

class PaintComponentLinkerTest < ActiveSupport::TestCase
  setup do
    ModelPaint.delete_all
    Model.delete_all
    Component.where(category: "paints").delete_all

    @linker = PaintComponentLinker.new
  end

  private def attach(record, attachment, filename)
    record.public_send(attachment).attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.png")),
      filename:,
      content_type: "image/png"
    )
    record
  end

  private def paint_for(model_name, paint_name)
    create(:model_paint, model: create(:model, name: model_name), name: paint_name)
  end

  private def paint_component(name)
    create(:component, category: "paints", name:)
  end

  private def linked_paint(with_image: true)
    paint = paint_for("Terrapin", "IceBreak")
    paint.update!(component: paint_component("Terrapin IceBreak Livery"))

    attach(paint, :store_image, "paint.png") if with_image

    paint
  end

  test "#run links a new paint and carries its artwork onto the component" do
    paint = attach(paint_for("Terrapin", "IceBreak"), :store_image, "paint.png")
    component = paint_component("Terrapin IceBreak Livery")

    @linker.run

    assert_equal component, paint.reload.component
    assert_predicate component.reload.store_image, :attached?
  end

  # Absent says the build does not ship it yet, which is the whole reason the
  # column is nullable.
  test "#link leaves a paint with no counterpart unlinked" do
    paint = paint_for("Terrapin", "IceBreak")
    paint_component("Nothing Like It Livery")

    @linker.link

    assert_nil paint.reload.component_id
  end

  test "#link is idempotent" do
    paint = paint_for("Terrapin", "IceBreak")
    paint_component("Terrapin IceBreak Livery")

    @linker.link
    updated_at = paint.reload.updated_at

    @linker.link

    assert_equal updated_at, paint.reload.updated_at, "an unchanged link should not be rewritten"
  end

  # Both Aurora liveries read as the one Foundation Festival paint, so moving
  # the link to whichever claims it last would flip it on every run.
  test "#link keeps a link once written" do
    paint = paint_for("Terrapin", "IceBreak")
    first = paint_component("Terrapin IceBreak Livery")
    paint.update!(component: first)
    paint_component("Terrapin IceBreak Livery (Modified)")

    @linker.link

    assert_equal first, paint.reload.component
  end

  test "#link moves a link off a component the build dropped" do
    paint = paint_for("Terrapin", "IceBreak")
    paint.update!(component: create(:component, :without_build, category: "paints", name: "Terrapin IceBreak Livery"))
    current = paint_component("Terrapin IceBreak Livery (Modified)")

    @linker.link

    assert_equal current, paint.reload.component
  end

  test "#link links nothing to a component the build dropped" do
    paint = paint_for("Terrapin", "IceBreak")
    create(:component, :without_build, category: "paints", name: "Terrapin IceBreak Livery")

    @linker.link

    assert_nil paint.reload.component_id
  end

  test "#link carries on past a paint that cannot be saved" do
    paint_for("Terrapin", "IceBreak")
    paint_for("Nomad", "Fortuna")
    paint_component("Terrapin IceBreak Livery")
    paint_component("Nomad Fortuna Livery")
    Appsignal.stubs(:report_error)
    ModelPaint.any_instance.expects(:update!).twice.raises(ActiveRecord::RecordInvalid).then.returns(true)

    @linker.link
  end

  # Losing the component must not take the paint with it.
  test "a destroyed component leaves its paints behind, unlinked" do
    paint = linked_paint(with_image: false)

    paint.component.destroy!

    assert ModelPaint.exists?(paint.id)
    assert_nil paint.reload.component_id
  end

  # Sharing one blob would mean purging the paint takes the component's
  # picture with it.
  test "#copy_store_images gives the component a blob of its own" do
    paint = linked_paint

    @linker.copy_store_images

    assert_not_equal paint.store_image.blob.id, paint.component.reload.store_image.blob.id
  end

  test "#copy_store_images leaves a curated picture alone" do
    paint = linked_paint
    attach(paint.component, :store_image, "curated.png")

    @linker.copy_store_images

    assert_equal "curated.png", paint.component.reload.store_image.filename.to_s
  end

  test "#copy_store_images does nothing for a paint carrying no picture" do
    paint = linked_paint(with_image: false)

    @linker.copy_store_images

    assert_not_predicate paint.component.reload.store_image, :attached?
  end

  test "#copy_store_images is idempotent" do
    paint = linked_paint

    @linker.copy_store_images
    blob_id = paint.component.reload.store_image.blob.id

    @linker.copy_store_images

    assert_equal blob_id, paint.component.reload.store_image.blob.id
  end
end
