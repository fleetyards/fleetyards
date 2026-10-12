# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261012160000_delete_unattached_legacy_components.rb")

class DeleteUnattachedLegacyComponentsTest < ActiveSupport::TestCase
  def legacy
    create(:component, :without_build, version: nil)
  end

  def run_migration
    DeleteUnattachedLegacyComponents.new.up
  end

  test "a component no build describes and nothing points at is deleted" do
    gone = legacy

    run_migration

    assert_not Component.exists?(gone.id)
  end

  test "a component a build describes is kept" do
    described = create(:component)

    run_migration

    assert Component.exists?(described.id)
  end

  test "a component loaded into a hardpoint is kept" do
    loaded = legacy
    create(:hardpoint, component: loaded)

    run_migration

    assert Component.exists?(loaded.id)
  end

  test "a component that owns hardpoints of its own is kept" do
    parent = legacy
    create(:hardpoint, parent:)

    run_migration

    assert Component.exists?(parent.id)
  end

  # Read off the schema, not a list: a polymorphic reference counts too.
  test "a component something prices is kept" do
    priced = legacy
    create(:item_price, item: priced)

    run_migration

    assert Component.exists?(priced.id)
  end
end
