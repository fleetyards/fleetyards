# == Schema Information
#
# Table name: hardpoints
#
#  id           :uuid             not null, primary key
#  group        :integer
#  max_size     :integer
#  min_size     :integer
#  parent_type  :string           not null
#  sc_name      :string
#  source       :integer
#  types        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  component_id :uuid
#  parent_id    :uuid             not null
#
# Indexes
#
#  index_hardpoints_on_component_id  (component_id)
#  index_hardpoints_on_parent        (parent_type,parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id)
#
class Hardpoint < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :component, optional: true
  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true

  enum source: {ship_matrix: 0, game_files: 1}
  enum group: {avionic: 0, system: 1, propulsion: 2, thruster: 3, weapon: 4, seat: 5, auxiliary: 6, other: 999}, _suffix: true

  before_validation :set_group

  def set_group
    return if component.blank?

    self.group = case component.category
    when "thrusters"
      :thruster
    when "seat"
      :seat
    when "selfdestruct", "lifesupport", "armor", "countermeasures", "batteries", "relay"
      :auxiliary
    when "radar", "computers", "scanners"
      :avionic
    when "powerplant", "cooler", "shieldgenerator", "module"
      :system
    when "turret", "weapon_mounts", "weapons", "missile_racks", "bombcompartments", "utility",
      "quantumenforcementdevice", "salvagemunching", "salvagefillerstation"
      :weapon
    when "fueltanks", "fuel_intakes", "quantumdrive"
      :propulsion
    else
      :other
    end
  end
end
