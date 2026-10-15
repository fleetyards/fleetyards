# frozen_string_literal: true

require "test_helper"

class HardpointCategoryTest < ActiveSupport::TestCase
  setup do
    @model = create(:model)
  end

  private def hardpoint(sc_name, component: nil)
    Hardpoint.create!(parent: @model, sc_name:, source: :game_files, component:)
  end

  test "an empty paint slot is a paint slot by its name" do
    %w[hardpoint_paint hardpoint_paint_seat hardpoint_paint_trim].each do |sc_name|
      assert_equal "paints", hardpoint(sc_name).category, sc_name
    end
  end

  test "a component fitted in a paint slot keeps deciding the category" do
    fitted = create(:component, category: "utility", component_type: "Misc")

    assert_equal "utility", hardpoint("hardpoint_paint", component: fitted).category
  end

  test "a slot without a component and without a telling name stays unknown" do
    assert_equal "unknown", hardpoint("hardpoint_whatever").category
  end
end
