# frozen_string_literal: true

require "test_helper"

class ModelPaintTest < ActiveSupport::TestCase
  test ".store_image_cache_key moves when a linked paint gains a store image" do
    paint = create(:model_paint, component: create(:component, category: "paints"))
    before = ModelPaint.store_image_cache_key

    paint.store_image.attach(io: file_fixture("test.png").open, filename: "paint.png", content_type: "image/png")

    refute_equal before, ModelPaint.store_image_cache_key
  end

  test ".store_image_cache_key moves when a paint is linked to a component" do
    paint = create(:model_paint)
    before = ModelPaint.store_image_cache_key

    paint.update!(component: create(:component, category: "paints"))

    refute_equal before, ModelPaint.store_image_cache_key
  end
end
