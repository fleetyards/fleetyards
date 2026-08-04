# frozen_string_literal: true

require "test_helper"

class ModelTest < ActiveSupport::TestCase
  test "#hangar_link_slug returns the legacy_slug when present" do
    manufacturer = create(:manufacturer, code: "DRAK")
    model = create(:model, name: "Corsair", manufacturer:)
    model.update_columns(legacy_slug: "corsair", slug: "drak-corsair")

    assert_equal "corsair", model.hangar_link_slug
  end

  test "#hangar_link_slug strips the manufacturer code prefix when no legacy_slug" do
    manufacturer = create(:manufacturer, code: "DRAK")
    model = create(:model, name: "Corsair", manufacturer:)
    model.update_columns(legacy_slug: nil, slug: "drak-corsair")

    assert_equal "corsair", model.hangar_link_slug
  end

  test "#hangar_link_slug returns the slug unchanged when it lacks the manufacturer prefix" do
    manufacturer = create(:manufacturer, code: "DRAK")
    model = create(:model, name: "Corsair", manufacturer:)
    model.update_columns(legacy_slug: nil, slug: "corsair")

    assert_equal "corsair", model.hangar_link_slug
  end
end
