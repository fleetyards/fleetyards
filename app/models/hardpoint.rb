class Hardpoint < ActiveRecord::Base
  translates :description

  belongs_to :weapon
  belongs_to :ship

  validates_presence_of :ship_id
  validates_inclusion_of :hp_class, in: Weapon::VALID_CLASSES, allow_nil: true

  before_validation :set_class

  private def set_class
    if weapon.present?
      self.hp_class = weapon.hp_class
    end
  end
end
