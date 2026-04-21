# frozen_string_literal: true

# == Schema Information
#
# Table name: cargo_holds
#
#  id                        :uuid             not null, primary key
#  capacity_scu              :decimal(15, 2)   not null
#  dimension_x               :decimal(15, 2)   not null
#  dimension_y               :decimal(15, 2)   not null
#  dimension_z               :decimal(15, 2)   not null
#  max_container_dimension_x :decimal(15, 2)
#  max_container_dimension_y :decimal(15, 2)
#  max_container_dimension_z :decimal(15, 2)
#  max_container_size_scu    :integer          not null
#  min_container_dimension_x :decimal(15, 2)
#  min_container_dimension_y :decimal(15, 2)
#  min_container_dimension_z :decimal(15, 2)
#  min_container_size_scu    :integer
#  name                      :string
#  offset_x                  :decimal(15, 2)
#  offset_y                  :decimal(15, 2)
#  offset_z                  :decimal(15, 2)
#  parent_type               :string           not null
#  position                  :integer
#  rotation                  :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  parent_id                 :uuid             not null
#
# Indexes
#
#  index_cargo_holds_on_capacity_scu                   (capacity_scu)
#  index_cargo_holds_on_parent_and_max_container_size  (parent_type,parent_id,max_container_size_scu)
#  index_cargo_holds_on_parent_type_and_parent_id      (parent_type,parent_id)
#
FactoryBot.define do
  factory :cargo_hold do
    association :parent, factory: :model
    name { "cargo_hold_#{SecureRandom.hex(4)}" }
    dimension_x { 5.0 }
    dimension_y { 2.5 }
    dimension_z { 2.5 }
    capacity_scu { 8 }
    max_container_size_scu { 8 }
    position { 0 }

    trait :for_module do
      association :parent, factory: :model_module
    end
  end
end
