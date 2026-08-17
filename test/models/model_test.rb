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
end
