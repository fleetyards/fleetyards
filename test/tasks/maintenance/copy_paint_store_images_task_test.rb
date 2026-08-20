# frozen_string_literal: true

require "test_helper"

module Maintenance
  class CopyPaintStoreImagesTaskTest < ActiveSupport::TestCase
    setup do
      ModelPaint.delete_all
      Model.delete_all
      Component.where(category: "paints").delete_all

      @task = ::Maintenance::CopyPaintStoreImagesTask.new
    end

    private def attach(record, attachment, filename)
      record.public_send(attachment).attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.png")),
        filename:,
        content_type: "image/png"
      )
      record
    end

    private def linked_paint(with_image: true)
      component = create(:component, category: "paints", name: "Terrapin IceBreak Livery")
      paint = create(:model_paint, model: create(:model, name: "Terrapin"), name: "IceBreak", component:)

      attach(paint, :store_image, "paint.png") if with_image

      paint
    end

    test "#process carries the artwork onto the linked component" do
      paint = linked_paint

      @task.process(paint)

      assert_predicate paint.component.reload.store_image, :attached?
    end

    # Sharing one blob would mean purging the paint takes the component's
    # picture with it.
    test "#process gives the component a blob of its own" do
      paint = linked_paint

      @task.process(paint)

      assert_not_equal paint.store_image.blob.id, paint.component.reload.store_image.blob.id
    end

    test "#process leaves a curated picture alone" do
      paint = linked_paint
      attach(paint.component, :store_image, "curated.png")

      @task.process(paint)

      assert_equal "curated.png", paint.component.reload.store_image.filename.to_s
    end

    test "#process does nothing for a paint carrying no picture" do
      paint = linked_paint(with_image: false)

      @task.process(paint)

      assert_not_predicate paint.component.reload.store_image, :attached?
    end

    test "#process is idempotent" do
      paint = linked_paint

      @task.process(paint)
      blob_id = paint.component.reload.store_image.blob.id

      @task.process(paint)

      assert_equal blob_id, paint.component.reload.store_image.blob.id
    end

    # Unlinked paints are the ones the build does not ship, so there is nothing
    # to copy onto.
    test "#collection covers only the linked paints" do
      linked = linked_paint
      create(:model_paint, model: create(:model, name: "Ursa"), name: "Fortuna")

      assert_equal [linked.id], @task.collection.map(&:id)
    end
  end
end
