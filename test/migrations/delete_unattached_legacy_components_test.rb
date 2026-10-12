# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261012160000_delete_unattached_legacy_components.rb")

class DeleteUnattachedLegacyComponentsTest < ActiveSupport::TestCase
  def legacy
    create(:component, :without_build, version: nil)
  end

  def run_migration
    ActiveRecord::Migration.suppress_messages { DeleteUnattachedLegacyComponents.new.up }
  end

  test "a component no build describes and nothing points at is deleted" do
    gone = legacy

    run_migration

    assert_not Component.exists?(gone.id)
  end

  test "a component from the game files is kept even without a build" do
    loaded = create(:component, :without_build, sc_ref: "e1f0a1b2-0000-4000-8000-000000000001")

    run_migration

    assert Component.exists?(loaded.id)
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

  test "a component's own history does not keep it" do
    edited = legacy
    PaperTrail::Version.create!(item: edited, event: "update")

    run_migration

    assert_not Component.exists?(edited.id)
  end

  test "a notification about a component does not keep it" do
    mentioned = legacy
    create(:notification, record: mentioned)

    run_migration

    assert_not Component.exists?(mentioned.id)
  end

  test "a component with only build changes left is deleted" do
    changed = legacy
    ComponentBuildChange.create!(
      component: changed, environment: "live", from_version: "4.0.0", to_version: "4.1.0",
      field: "name", recorded_at: Time.current
    )

    run_migration

    assert_not Component.exists?(changed.id)
  end
end
