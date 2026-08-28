# frozen_string_literal: true

# == Schema Information
#
# Table name: model_builds
#
#  id                      :uuid             not null, primary key
#  cargo_holds             :string
#  environment             :string           not null
#  external_fuel_tanks     :string
#  fuel_consumption        :decimal(15, 2)
#  ground                  :boolean          default(FALSE)
#  ground_acceleration     :decimal(15, 2)
#  ground_decceleration    :decimal(15, 2)
#  ground_max_speed        :decimal(15, 2)
#  ground_reverse_speed    :decimal(15, 2)
#  hull_doors              :jsonb
#  hull_health             :decimal(15, 2)
#  hull_parts              :jsonb
#  hydrogen_fuel_tanks     :string
#  main_acceleration       :decimal(15, 2)
#  mass                    :decimal(15, 2)
#  max_speed               :decimal(15, 2)
#  personal_inventory      :decimal(15, 2)
#  pitch                   :decimal(15, 2)
#  pitch_boosted           :decimal(15, 2)
#  quantum_fuel_tanks      :string
#  refuel_boom             :string
#  retro_acceleration      :decimal(15, 2)
#  reverse_speed_boosted   :decimal(15, 2)
#  roll                    :decimal(15, 2)
#  roll_boosted            :decimal(15, 2)
#  scm_speed               :decimal(15, 2)
#  scm_speed_boosted       :decimal(15, 2)
#  signature_cross_section :jsonb
#  version                 :string           not null
#  weapon_pool_size        :integer
#  yaw                     :decimal(15, 2)
#  yaw_boosted             :decimal(15, 2)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid             not null
#
# Indexes
#
#  index_model_builds_on_environment_and_version  (environment,version)
#  index_model_builds_on_model_and_build          (model_id,environment,version) UNIQUE
#  index_model_builds_on_model_id                 (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :model_build do
    model
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    mass { 1_500.0 }
    scm_speed { 210.0 }
    max_speed { 1_200.0 }
    ground { false }
  end
end
