class Equipment < ActiveRecord::Base
  translates :description

  has_and_belongs_to_many :ships

  VALID_LIMITED_TYPES = %w(shield powerplant thrusters primary_thrusters)
  VALID_TYPES = VALID_LIMITED_TYPES + %w(additional)

  validates_presence_of :name, :equipment_type
  validates_inclusion_of :equipment_type, in: self::VALID_TYPES
end
