# frozen_string_literal: true

require "test_helper"

class ModelHardpointTransformsTest < ActiveSupport::TestCase
  test "touches the ship, whose holds it places" do
    model = create(:model)
    model.update!(hardpoint_transforms: {"cargo_grids" => []})
    before = model.reload.updated_at

    travel 1.minute do
      model.hardpoint_transforms_record.update!(data: {"cargo_grids" => [{"name" => "grid"}]})
    end

    assert_operator model.reload.updated_at, :>, before
  end
end
