class Weapon < ActiveRecord::Base
  translates :description

  has_many :hardpoints
  has_many :ships, through: :hardpoints

  VALID_CLASSES = %w(class1 class2 class3 class4 class5 class6 class7 class8)

  validates_presence_of :name, :hp_class
  validates :hp_class, inclusion: { in: self::VALID_CLASSES }
end
