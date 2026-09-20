# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260920140000_make_variant_families_consistent.rb")

class MakeVariantFamiliesConsistentTest < ActiveSupport::TestCase
  # `update_slugs` derives the slug on every save, so one handed to the factory
  # does not survive.
  def ship(slug, **attributes)
    model = create(:model, **attributes)
    Model.where(id: model.id).update_all(slug: slug)
    model.reload
  end

  def run_migration
    MakeVariantFamiliesConsistent.new.up
  end

  test "the one member without a base joins its family" do
    cyclone = ship("tmbl-cyclone", rsi_chassis_id: 53)
    cyclone.update_columns(base_model_id: cyclone.id)
    rn = ship("tmbl-cyclone-rn", rsi_chassis_id: 53)

    run_migration

    assert_equal cyclone.id, rn.reload.base_model_id
    assert_includes cyclone.variants.map(&:id), rn.id
  end

  test "the only member with a base gives it up so the chassis answers" do
    heartseeker = ship("anvl-f7c-m-super-hornet-heartseeker-mk-i", rsi_chassis_id: 3)
    super_hornet = ship("anvl-f7c-m-super-hornet-mk-i", rsi_chassis_id: 3)
    heartseeker.update_columns(base_model_id: super_hornet.id)

    assert_empty heartseeker.reload.variants

    run_migration

    assert_nil heartseeker.reload.base_model_id
    assert_includes heartseeker.variants.map(&:id), super_hornet.id
  end

  test "a family that has since been linked keeps its base" do
    heartseeker = ship("anvl-f7c-m-super-hornet-heartseeker-mk-i", rsi_chassis_id: 3)
    super_hornet = ship("anvl-f7c-m-super-hornet-mk-i", rsi_chassis_id: 3)
    heartseeker.update_columns(base_model_id: super_hornet.id)
    super_hornet.update_columns(base_model_id: super_hornet.id)

    run_migration

    assert_equal super_hornet.id, heartseeker.reload.base_model_id
  end

  test "a base somebody has already set is not overwritten" do
    ship("tmbl-cyclone", rsi_chassis_id: 53)
    rn = ship("tmbl-cyclone-rn", rsi_chassis_id: 53)
    rn.update_columns(base_model_id: rn.id)

    run_migration

    assert_equal rn.id, rn.reload.base_model_id
  end

  test "it does not roll back" do
    assert_raises(ActiveRecord::IrreversibleMigration) { MakeVariantFamiliesConsistent.new.down }
  end
end
