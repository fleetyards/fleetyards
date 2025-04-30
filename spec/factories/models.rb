# == Schema Information
#
# Table name: models
#
#  id                         :uuid             not null, primary key
#  active                     :boolean          default(TRUE)
#  angled_view                :string
#  angled_view_colored        :string
#  angled_view_colored_height :integer
#  angled_view_colored_width  :integer
#  angled_view_height         :integer
#  angled_view_width          :integer
#  beam                       :decimal(15, 2)   default(0.0), not null
#  brochure                   :string
#  cargo                      :decimal(15, 2)
#  cargo_holds                :string
#  classification             :string(255)
#  description                :text
#  dock_size                  :integer
#  erkul_identifier           :string
#  fleetchart_image           :string
#  fleetchart_image_height    :integer
#  fleetchart_image_width     :integer
#  fleetchart_offset_length   :decimal(15, 2)
#  focus                      :string(255)
#  front_view                 :string
#  front_view_colored         :string
#  front_view_colored_height  :integer
#  front_view_colored_width   :integer
#  front_view_height          :integer
#  front_view_width           :integer
#  fuel_consumption           :decimal(15, 2)
#  ground                     :boolean          default(FALSE)
#  ground_acceleration        :decimal(15, 2)
#  ground_decceleration       :decimal(15, 2)
#  ground_max_speed           :decimal(15, 2)
#  ground_reverse_speed       :decimal(15, 2)
#  height                     :decimal(15, 2)   default(0.0), not null
#  hidden                     :boolean          default(TRUE)
#  holo                       :string
#  holo_colored               :boolean          default(FALSE)
#  hydrogen_fuel_tank_size    :decimal(15, 2)
#  hydrogen_fuel_tanks        :string
#  images_count               :integer          default(0)
#  last_pledge_price          :decimal(15, 2)
#  last_updated_at            :datetime
#  length                     :decimal(15, 2)   default(0.0), not null
#  loaners_count              :integer          default(0), not null
#  mass                       :decimal(15, 2)   default(0.0), not null
#  max_crew                   :integer
#  max_speed                  :decimal(15, 2)
#  max_speed_acceleration     :decimal(15, 2)
#  max_speed_decceleration    :decimal(15, 2)
#  min_crew                   :integer
#  model_paints_count         :integer          default(0)
#  module_hardpoints_count    :integer          default(0)
#  name                       :string(255)
#  notified                   :boolean          default(FALSE)
#  on_sale                    :boolean          default(FALSE)
#  pitch                      :decimal(15, 2)
#  pitch_boosted              :decimal(15, 2)
#  pledge_price               :decimal(15, 2)
#  price                      :decimal(15, 2)
#  production_note            :string(255)
#  production_status          :string(255)
#  quantum_fuel_tank_size     :decimal(15, 2)
#  quantum_fuel_tanks         :string
#  reverse_speed_boosted      :decimal(15, 2)
#  roll                       :decimal(15, 2)
#  roll_boosted               :decimal(15, 2)
#  rsi_beam                   :decimal(15, 2)   default(0.0), not null
#  rsi_cargo                  :decimal(15, 2)
#  rsi_classification         :string
#  rsi_description            :text
#  rsi_focus                  :string
#  rsi_height                 :decimal(15, 2)   default(0.0), not null
#  rsi_length                 :decimal(15, 2)   default(0.0), not null
#  rsi_mass                   :decimal(15, 2)   default(0.0), not null
#  rsi_max_crew               :integer
#  rsi_max_speed              :decimal(15, 2)
#  rsi_min_crew               :integer
#  rsi_name                   :string
#  rsi_pitch                  :decimal(15, 2)
#  rsi_roll                   :decimal(15, 2)
#  rsi_scm_speed              :decimal(15, 2)
#  rsi_size                   :string
#  rsi_slug                   :string
#  rsi_store_image            :string
#  rsi_store_image_height     :integer
#  rsi_store_image_width      :integer
#  rsi_store_url              :string
#  rsi_yaw                    :decimal(15, 2)
#  sales_page_url             :string
#  sc_beam                    :decimal(15, 2)
#  sc_height                  :decimal(15, 2)
#  sc_identifier              :string
#  sc_length                  :decimal(15, 2)
#  scm_speed                  :decimal(15, 2)
#  scm_speed_acceleration     :decimal(15, 2)
#  scm_speed_boosted          :decimal(15, 2)
#  scm_speed_decceleration    :decimal(15, 2)
#  side_view                  :string
#  side_view_colored          :string
#  side_view_colored_height   :integer
#  side_view_colored_width    :integer
#  side_view_height           :integer
#  side_view_width            :integer
#  size                       :string
#  slug                       :string(255)
#  store_image                :string(255)
#  store_image_height         :integer
#  store_image_width          :integer
#  store_images_updated_at    :datetime
#  store_url                  :string(255)
#  top_view                   :string
#  top_view_colored           :string
#  top_view_colored_height    :integer
#  top_view_colored_width     :integer
#  top_view_height            :integer
#  top_view_width             :integer
#  upgrade_kits_count         :integer          default(0)
#  videos_count               :integer          default(0)
#  yaw                        :decimal(15, 2)
#  yaw_boosted                :decimal(15, 2)
#  created_at                 :datetime
#  updated_at                 :datetime
#  base_model_id              :uuid
#  manufacturer_id            :uuid
#  rsi_chassis_id             :integer
#  rsi_id                     :integer
#
# Indexes
#
#  index_models_on_base_model_id  (base_model_id)
#
FactoryBot.define do
  factory :model do
    name { Faker::Name.name }
    beam { 27.75 }
    cargo { 96 }
    classification { :multi_role }
    focus { :combat }
    size { :large }
    height { 15.25 }
    hidden { false }
    images_count { 0 }
    last_pledge_price { 225 }
    length { 63.5 }
    manufacturer
    mass { 430057.0 }
    max_crew { 4 }
    min_crew { 3 }
    model_paints_count { 0 }
    module_hardpoints_count { 0 }
    rsi_chassis_id { 45 }
    rsi_id { 45 }
    upgrade_kits_count { 0 }
    videos_count { 0 }
    ground { false }
    hydrogen_fuel_tank_size { 660000.0 }
    quantum_fuel_tank_size { 3000.0 }
    scm_speed { 144.0 }
    max_speed { 911.0 }
    scm_speed_acceleration { 3.11 }
    scm_speed_decceleration { 6.22 }
    max_speed_acceleration { 19.66 }
    max_speed_decceleration { 39.35 }
    pitch { 25.0 }
    yaw { 25.0 }
    roll { 65.0 }

    trait :with_images do
      after(:create) do |model|
        create_list(:image, 3, gallery: model)
      end
    end

    trait :with_videos do
      after(:create) do |model|
        create_list(:video, 3, model: model)
      end
    end

    trait :with_hardpoints do
      after(:create) do |model|
        create_list(:model_hardpoint, 3, model: model)
      end
    end

    trait :with_upgrades do
      after(:create) do |model|
        create_list(:model_upgrade, 3, models: [model])
      end
    end

    trait :with_snub_crafts do
      after(:create) do |model|
        create_list(:model_snub_craft, 3, model: model)
      end
    end

    trait :with_paints do
      after(:create) do |model|
        create_list(:model_paint, 3, model: model)
      end
    end

    trait :with_modules do
      after(:create) do |model|
        create_list(:module_hardpoint, 3, model: model)
      end
    end

    trait :with_variants do
      after(:create) do |model|
        create_list(:model, 3, base_model_id: model.id)
      end
    end

    trait :with_module_packages do
      after(:create) do |model|
        create_list(:model_module_package, 3, model: model)
      end
    end

    trait :with_loaners do
      after(:create) do |model|
        create_list(:model_loaner, 3, model: model)
      end
    end

    trait :with_legacy_images do
      fleetchart_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/jpeg") }
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/jpeg") }
    end

    trait :with_docks do
      after(:create) do |model|
        create_list(:dock, 3, model: model)
      end
    end
  end
end
