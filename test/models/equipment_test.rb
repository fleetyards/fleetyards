# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  equipment_type         :integer
#  extras                 :string
#  grade                  :string
#  hidden                 :boolean          default(TRUE)
#  item_type              :integer
#  name                   :string
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  size                   :string
#  slot                   :integer
#  slug                   :string
#  storage                :decimal(15, 2)
#  store_image            :string
#  temperature_rating     :string
#  volume                 :decimal(15, 2)
#  weapon_class           :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_on_manufacturer_id  (manufacturer_id)
#
require "test_helper"

class EquipmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
