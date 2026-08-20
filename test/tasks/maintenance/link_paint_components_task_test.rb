# frozen_string_literal: true

require "test_helper"

module Maintenance
  class LinkPaintComponentsTaskTest < ActiveSupport::TestCase
    setup do
      ModelPaint.delete_all
      Model.delete_all
      Component.where(category: "paints").delete_all

      @task = ::Maintenance::LinkPaintComponentsTask.new
    end

    private def paint_for(model_name, paint_name)
      create(:model_paint, model: create(:model, name: model_name), name: paint_name)
    end

    private def paint_component(name)
      create(:component, category: "paints", name:)
    end

    test "#process records the component a paint corresponds to" do
      paint = paint_for("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")

      @task.process(component)

      assert_equal component, paint.reload.component
    end

    # Absent says the build does not ship it yet, which is the whole reason the
    # column is nullable.
    test "#process leaves a paint with no counterpart unlinked" do
      paint = paint_for("Terrapin", "IceBreak")
      @task.process(paint_component("Nothing Like It Livery"))

      assert_nil paint.reload.component_id
    end

    test "#process is idempotent" do
      paint = paint_for("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")

      @task.process(component)
      updated_at = paint.reload.updated_at

      @task.process(component)

      assert_equal updated_at, paint.reload.updated_at, "an unchanged link should not be rewritten"
    end

    # Losing the component must not take the paint with it.
    test "a destroyed component leaves its paints behind, unlinked" do
      paint = paint_for("Terrapin", "IceBreak")
      component = paint_component("Terrapin IceBreak Livery")
      @task.process(component)

      component.destroy!

      assert ModelPaint.exists?(paint.id)
      assert_nil paint.reload.component_id
    end
  end
end
