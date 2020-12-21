# frozen_string_literal: true

# == Schema Information
#
# Table name: model_hardpoints
#
#  id             :uuid             not null, primary key
#  category       :integer
#  deleted_at     :datetime
#  details        :string
#  group          :integer
#  hardpoint_type :integer
#  item_slots     :integer
#  key            :string
#  mount          :string
#  size           :integer
#  source         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  component_id   :uuid
#  model_id       :uuid
#
# Indexes
#
#  index_model_hardpoints_on_component_id  (component_id)
#  index_model_hardpoints_on_model_id      (model_id)
#
class ModelHardpoint < ApplicationRecord
  belongs_to :model, touch: true
  belongs_to :component, optional: true

  validates :model_id, :source, :key, :hardpoint_type, :group, presence: true

  enum source: { ship_matrix: 0, game_files: 1 }

  after_save :update_model

  GAME_FILE_HARDPOINT_TYPES = {
    power_plants: 10, coolers: 11, shield_generators: 12,
    quantum_drives: 22,
    weapons: 40, turrets: 41, missiles: 42,
  }.freeze

  SHIP_MATRIX_HARDPOINT_TYPES = {
    radar: 0, computers: 1,
    fuel_intakes: 20, fuel_tanks: 21, jump_modules: 23, quantum_fuel_tanks: 24,
    main_thrusters: 30, maneuvering_thrusters: 31,
    utility_items: 43
  }.freeze

  enum hardpoint_type: SHIP_MATRIX_HARDPOINT_TYPES.merge(GAME_FILE_HARDPOINT_TYPES)

  enum group: { avionic: 0, system: 1, propulsion: 2, thruster: 3, weapon: 4 }

  enum category: {
    main: 0, retro: 1, vtol: 2, fixed: 3, gimbal: 4, joint: 5,
    manned_turret: 20, remote_turret: 21, missile_rack: 30
  }

  enum size: {
    vehicle: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9,
    ten: 10, eleven: 11, twelve: 12, small: 101, medium: 102, large: 103, capital: 104, tbd: 999
  }

  def self.types_by_group
    types_by_group = {}

    groups.each do |group, index|
      start_index = index * 10
      end_index = (index + 1) * 10

      types_by_group[group] = hardpoint_types.select do |_type, type_index|
        (start_index...end_index).cover?(type_index)
      end
    end

    types_by_group
  end

  def update_model
    return unless %i[cargo quantum_fuel_tanks fuel_tanks].include?(hardpoint_type)

    model.update_from_hardpoints
  end

  def self.undeleted
    where(deleted_at: nil)
  end

  def self.deleted
    where.not(deleted_at: nil)
  end

  def category_label
    ModelHardpoint.human_enum_name(:category, category)
  end

  def size_label
    ModelHardpoint.human_enum_name(:size, size)
  end
end
