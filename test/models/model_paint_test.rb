# frozen_string_literal: true

require "test_helper"

class ModelPaintTest < ActiveSupport::TestCase
  test "strips stray whitespace from its name" do
    assert_equal "Stormbringer", create(:model_paint, name: " Stormbringer\t").name
    assert_equal "Stormbringer", create(:model_paint, name: "Stormbringer\u00A0").name
  end
end
