# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: models
#
#  id                                :uuid             not null, primary key
#  active                            :boolean          default(TRUE)
#  adi_map                           :boolean          default(FALSE)
#  beam                              :decimal(15, 2)   default(0.0), not null
#  cargo                             :decimal(15, 2)
#  cargo_holds                       :string
#  classification                    :string(255)
#  description                       :text
#  dock_size                         :integer
#  erkul_identifier                  :string
#  extended_beam                     :decimal(15, 2)
#  extended_fleetchart_offset_beam   :decimal(15, 2)
#  extended_fleetchart_offset_length :decimal(15, 2)
#  extended_height                   :decimal(15, 2)
#  extended_length                   :decimal(15, 2)
#  external_fuel_tanks               :string
#  fleetchart_offset_beam            :decimal(15, 2)
#  fleetchart_offset_length          :decimal(15, 2)
#  focus                             :string(255)
#  fuel_consumption                  :decimal(15, 2)
#  ground                            :boolean          default(FALSE)
#  ground_acceleration               :decimal(15, 2)
#  ground_decceleration              :decimal(15, 2)
#  ground_max_speed                  :decimal(15, 2)
#  ground_reverse_speed              :decimal(15, 2)
#  height                            :decimal(15, 2)   default(0.0), not null
#  hidden                            :boolean          default(TRUE)
#  holo_colored                      :boolean          default(FALSE)
#  hull_doors                        :jsonb
#  hull_health                       :decimal(15, 2)
#  hull_parts                        :jsonb
#  hydrogen_fuel_tank_size           :decimal(15, 2)
#  hydrogen_fuel_tanks               :string
#  images_count                      :integer          default(0)
#  in_game                           :boolean          default(FALSE), not null
#  last_updated_at                   :datetime
#  legacy_slug                       :string
#  length                            :decimal(15, 2)   default(0.0), not null
#  loaners_count                     :integer          default(0), not null
#  mass                              :decimal(15, 2)   default(0.0), not null
#  max_crew                          :integer
#  max_speed                         :decimal(15, 2)
#  max_speed_acceleration            :decimal(15, 2)
#  max_speed_decceleration           :decimal(15, 2)
#  min_crew                          :integer
#  model_paints_count                :integer          default(0)
#  module_hardpoints_count           :integer          default(0)
#  name                              :string(255)
#  notified                          :boolean          default(FALSE)
#  on_sale                           :boolean          default(FALSE)
#  personal_inventory                :decimal(15, 2)
#  pitch                             :decimal(15, 2)
#  pitch_boosted                     :decimal(15, 2)
#  player_ownable                    :boolean          default(TRUE), not null
#  pledge_price                      :decimal(15, 2)
#  positions_need_curation           :boolean          default(FALSE)
#  price                             :decimal(15, 2)
#  production_note                   :string(255)
#  production_status                 :string(255)
#  quantum_fuel_tank_size            :decimal(15, 2)
#  quantum_fuel_tanks                :string
#  refuel_boom                       :string
#  reverse_speed_boosted             :decimal(15, 2)
#  roll                              :decimal(15, 2)
#  roll_boosted                      :decimal(15, 2)
#  rsi_beam                          :decimal(15, 2)   default(0.0), not null
#  rsi_cargo                         :decimal(15, 2)
#  rsi_classification                :string
#  rsi_ctm_url                       :string
#  rsi_description                   :text
#  rsi_focus                         :string
#  rsi_height                        :decimal(15, 2)   default(0.0), not null
#  rsi_length                        :decimal(15, 2)   default(0.0), not null
#  rsi_mass                          :decimal(15, 2)   default(0.0), not null
#  rsi_max_crew                      :integer
#  rsi_max_speed                     :decimal(15, 2)
#  rsi_min_crew                      :integer
#  rsi_name                          :string
#  rsi_pitch                         :decimal(15, 2)
#  rsi_pledge_slug                   :string
#  rsi_pledge_value                  :integer
#  rsi_roll                          :decimal(15, 2)
#  rsi_scm_speed                     :decimal(15, 2)
#  rsi_size                          :string
#  rsi_slug                          :string
#  rsi_store_url                     :string
#  rsi_yaw                           :decimal(15, 2)
#  sales_page_url                    :string
#  sc_beam                           :decimal(15, 2)
#  sc_height                         :decimal(15, 2)
#  sc_key                            :string
#  sc_length                         :decimal(15, 2)
#  scm_speed                         :decimal(15, 2)
#  scm_speed_acceleration            :decimal(15, 2)
#  scm_speed_boosted                 :decimal(15, 2)
#  scm_speed_decceleration           :decimal(15, 2)
#  signature_cross_section           :jsonb
#  size                              :string
#  slug                              :string(255)
#  store_images_updated_at           :datetime
#  store_url                         :string(255)
#  upgrade_kits_count                :integer          default(0)
#  videos_count                      :integer          default(0)
#  weapon_pool_size                  :integer
#  yaw                               :decimal(15, 2)
#  yaw_boosted                       :decimal(15, 2)
#  created_at                        :datetime
#  updated_at                        :datetime
#  base_model_id                     :uuid
#  manufacturer_id                   :uuid
#  rsi_chassis_id                    :integer
#  rsi_id                            :integer
#
# Indexes
#
#  index_models_on_base_model_id             (base_model_id)
#  index_models_on_classification            (classification)
#  index_models_on_legacy_slug               (legacy_slug)
#  index_models_on_manufacturer_id           (manufacturer_id)
#  index_models_on_manufacturer_id_and_name  (manufacturer_id,name) UNIQUE
#  index_models_on_production_status         (production_status)
#  index_models_on_size                      (size)
#
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

  test "#personal_inventory_label keeps the fraction most ships store in" do
    model = create(:model, name: "Cutlass Red", personal_inventory: 3.43)

    assert_equal "3.43 SCU", model.personal_inventory_label
  end

  test "#personal_inventory_label is blank without a storage container" do
    model = create(:model, name: "No Storage", personal_inventory: nil)

    assert_nil model.personal_inventory_label
  end

  # Every test here makes the build **disagree** with the column. While the
  # loader writes both they are identical, so a passing test would otherwise
  # prove nothing about which side answered.
  test "a model in the current build reads that build's mechanics" do
    model = create(:model, mass: 100.0, scm_speed: 50.0)
    create(:model_build, model:, mass: 999.0, scm_speed: 111.0)

    assert_equal 999.0, model.reload.mass
    assert_equal 111.0, model.scm_speed
  end

  # A hangar entry pointing at a ship the export dropped still has to resolve, so
  # the last build of this environment answers rather than nothing.
  test "a model the current build dropped reads the last build that described it" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, version: "0.0.1-live.1", mass: 777.0)

    assert_nil model.reload.build
    assert_equal 777.0, model.mass
  end

  test "the current build wins over an earlier one" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, version: "0.0.1-live.1", mass: 777.0)
    create(:model_build, model:, mass: 999.0)

    assert_equal 999.0, model.reload.mass
  end

  # Every concept ship, and every ship the export dropped before the build table
  # existed. 31 of 246 models in a full dataset have no build at all.
  test "a model with no build at all falls back to its own columns" do
    model = create(:model, mass: 100.0, scm_speed: 50.0)

    assert_nil model.build
    assert_equal 100.0, model.mass
    assert_equal 50.0, model.scm_speed
  end

  # The build carries no `rsi_*` column, and the matrix is deliberately not a
  # read layer: for a ship with no build the column already holds the matrix
  # value, and for one the export dropped it holds a real game-file value.
  test "the ship matrix does not override what a build says" do
    model = create(:model, mass: 100.0, rsi_mass: 555.0)
    create(:model_build, model:, mass: 999.0)

    assert_equal 999.0, model.reload.mass
  end

  test "the ship matrix does not override the column when there is no build" do
    model = create(:model, mass: 100.0, rsi_mass: 555.0)

    assert_equal 100.0, model.mass
  end

  # All five, because the reader falls through to the column only on nil and a
  # raw YAML string is not nil -- the shape that broke the components loader.
  test "a serialized fact read off the build keeps its structure" do
    cargo_holds = [{"capacity" => 6, "dimensions" => {"x" => 1.25}}]
    refuel_boom = {"name" => "refuel_boom", "rate" => 5.0}
    model = create(:model, cargo_holds: [{"capacity" => 1}])
    create(:model_build, model:, cargo_holds:, refuel_boom:)

    model.reload

    assert_equal cargo_holds, model.cargo_holds
    assert_equal refuel_boom, model.refuel_boom
  end

  test "a jsonb fact read off the build keeps its structure" do
    hull_parts = [{"name" => "hull_front", "health" => 12_000.0}]
    model = create(:model)
    create(:model_build, model:, hull_parts:)

    assert_equal hull_parts, model.reload.hull_parts
  end

  test "#update_with_facts writes the correction to the build as well" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, mass: 999.0)

    assert model.reload.update_with_facts(mass: 250.0)

    assert_equal 250.0, model.build.reload.mass
    assert_equal 250.0, model.reload.mass
  end

  # `author_id` and `update_reason` are `attr_accessor`s for paper_trail's meta,
  # and the admin controller merges them into the same hash the build is sliced
  # from.
  test "#update_with_facts keeps paper_trail's meta off the build" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, mass: 999.0)

    assert model.reload.update_with_facts(mass: 250.0, update_reason: :custom, author_id: nil)

    assert_equal 250.0, model.build.reload.mass
  end

  test "#update_with_facts leaves a dropped model's build alone" do
    model = create(:model, mass: 100.0)
    old = create(:model_build, model:, version: "0.0.1-live.1", mass: 777.0)

    assert model.reload.update_with_facts(mass: 250.0)

    assert_equal 777.0, old.reload.mass
  end

  # Filtering and sorting, made to disagree with the column -- while the loader
  # writes both they are identical, so a passing test would prove nothing.
  test "filters on the mass the build carries, not the column" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, mass: 999_999.0)

    assert_includes Model.ransack(mass_gteq: 500_000).result, model
    assert_not_includes Model.ransack(mass_lteq: 500).result, model
  end

  test "sorts by the speed the build carries, not the column" do
    slow = create(:model, name: "Zzz", scm_speed: 900.0)
    fast = create(:model, name: "Aaa", scm_speed: 10.0)
    create(:model_build, model: slow, scm_speed: 10.0)
    create(:model_build, model: fast, scm_speed: 900.0)

    assert_equal [fast, slow], Model.where(id: [slow.id, fast.id]).ransack(sorts: "scm_speed desc").result.to_a
  end

  # 31 of 246 models in a full dataset are concept ships no build describes. A
  # filter that dropped them would empty the catalogue of everything not flying.
  test "a model with no build is still found by what its column says" do
    model = create(:model, mass: 4_242.0)

    assert_nil model.build
    assert_includes Model.ransack(mass_gteq: 4_000).result, model
  end

  test "an older build does not answer a filter" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, version: "0.0.1-live.1", mass: 999_999.0)

    assert_not_includes Model.ransack(mass_gteq: 500_000).result, model,
      "only the build we are on decides a filter"
    assert_includes Model.ransack(mass_lteq: 500).result, model
  end

  # The reason this uses a subquery rather than the joined alias the other three
  # catalogues use: ransack builds the association join itself, so an expression
  # naming an alias nobody joined raises PG::UndefinedTable.
  test "a vehicle sorts by a model fact through its association" do
    slow = create(:model, name: "Zzz", mass: 900.0)
    fast = create(:model, name: "Aaa", mass: 10.0)
    create(:model_build, model: slow, mass: 10.0)
    create(:model_build, model: fast, mass: 900.0)
    user = create(:user)
    a = create(:vehicle, model: slow, user:)
    b = create(:vehicle, model: fast, user:)

    assert_equal [b, a], user.vehicles.ransack(sorts: "model_mass desc").result.to_a
  end

  test "a vehicle filters on a model fact through its association" do
    model = create(:model, mass: 100.0)
    create(:model_build, model:, mass: 999_999.0)
    user = create(:user)
    vehicle = create(:vehicle, model:, user:)

    assert_includes user.vehicles.ransack(model_mass_gteq: 500_000).result, vehicle
  end
end
