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
    slot = create(:hardpoint, component: cannon)
    build = create(:hardpoint_build, component: cannon)

    run_migration

    assert_not Component.exists?(cannon.id)
    assert_nil slot.reload.component_id
    assert_nil build.reload.component_id
  end

  test "a key that only contains the word is kept" do
    kept = create(:component, sc_key: "radr_grnp_s03_devoue")
    contested = create(:component, sc_key: "shld_contested_s01")

    run_migration

    assert Component.exists?(kept.id)
    assert Component.exists?(contested.id)
  end

  test "a stand-in a player's data points at is kept" do
    carted = create(:component, sc_key: "mining_laser_test")
    create(:cart_item, item: carted)

    run_migration

    assert Component.exists?(carted.id)
  end
end
