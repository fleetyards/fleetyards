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

    private def paint_with_image(model_name, paint_name)
      paint = create(:model_paint, model: create(:model, name: model_name), name: paint_name)
      paint.store_image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.png")),
        filename: "test.png",
        content_type: "image/png"
      )
      paint
    end

    private def paint_component(name)
      create(:component, category: "paints", name:)
    end

    test "#process carries the artwork onto a matched component" do
      paint_with_image("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")

      @task.process(component)

      assert_predicate component.reload.store_image, :attached?
    end

    # Sharing one blob would mean purging the paint takes the component's
    # picture with it.
    test "#process gives the component a blob of its own" do
      paint = paint_with_image("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")

      @task.process(component)

      assert_not_equal paint.store_image.blob.id, component.reload.store_image.blob.id
    end

    test "#process leaves a curated picture alone" do
      paint_with_image("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")
      component.store_image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.png")),
        filename: "curated.png",
        content_type: "image/png"
      )

      @task.process(component)

      assert_equal "curated.png", component.reload.store_image.filename.to_s
    end

    test "#process does nothing for a component no paint matches" do
      paint_with_image("Terrapin", "IceBreak")
      component = paint_component("Nothing Like It Livery")

      @task.process(component)

      assert_not_predicate component.reload.store_image, :attached?
    end

    # Re-running has to be safe: the task is the thing that gets restarted when
    # matching improves.
    test "#process is idempotent" do
      paint_with_image("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")

      @task.process(component)
      blob_id = component.reload.store_image.blob.id

      @task.process(component)

      assert_equal blob_id, component.reload.store_image.blob.id
    end

    test "#collection covers the named paint components" do
      paint_component("Terrapin IceBreak Livery")
      create(:component, category: "weapons", name: "Not A Paint")

      assert_equal ["Terrapin IceBreak Livery"], @task.collection.map(&:name)
    end
  end
end
