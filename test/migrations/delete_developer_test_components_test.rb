# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261116120000_delete_developer_test_components.rb")

class DeleteDeveloperTestComponentsTest < ActiveSupport::TestCase
  def run_migration
    ActiveRecord::Migration.suppress_messages { DeleteDeveloperTestComponents.new.up }
  end

  test "a test or dummy item is deleted with its prices and ports" do
    mine = create(:component, sc_key: "mine_test")
    cannon = create(:component, sc_key: "behr_lasercannon_s7_idris_m_dummy")
    create(:item_price, item: mine)
    create(:hardpoint, parent: mine)

    run_migration

    assert_not Component.exists?(mine.id)
    assert_not Component.exists?(cannon.id)
    assert_not ItemPrice.exists?(item_id: mine.id)
    assert_not Hardpoint.exists?(parent_id: mine.id)
  end

  test "a ship slot loaded with a dummy is emptied rather than kept" do
    cannon = create(:component, sc_key: "behr_javelinballisticcannon_s7_dummy")
    hull = create(:model)
    turret = create(:hardpoint, parent: hull)
    slot = create(:hardpoint, parent: turret, component: cannon)
    build = create(:hardpoint_build, component: cannon)

    travel(1.hour) { run_migration }

    assert_not Component.exists?(cannon.id)
    assert_nil slot.reload.component_id
    assert_nil build.reload.component_id
    assert_operator hull.reload.updated_at, :>, 30.minutes.from_now, "the hull caching the turret's ports has to be touched"
  end

  test "a key that only contains the word is kept" do
    contested = create(:component, sc_key: "shld_contested_s01")
    dummyless = create(:component, sc_key: "radr_dummyless_s03")

    run_migration

    assert Component.exists?(contested.id)
    assert Component.exists?(dummyless.id)
  end

  test "a stand-in a player's data points at is kept" do
    carted = create(:component, sc_key: "mining_laser_test")
    create(:cart_item, item: carted)

    run_migration

    assert Component.exists?(carted.id)
  end

  test "a stand-in with a curated store image is kept, its game icon does not keep it" do
    pictured = create(:component, sc_key: "mine_test")
    pictured.store_image.attach(io: StringIO.new("png"), filename: "store.png", content_type: "image/png")
    iconed = create(:component, sc_key: "mine_test_placeable")
    iconed.icon.attach(io: StringIO.new("png"), filename: "icon.png", content_type: "image/png")

    run_migration

    assert Component.exists?(pictured.id)
    assert_not Component.exists?(iconed.id)
  end
end
