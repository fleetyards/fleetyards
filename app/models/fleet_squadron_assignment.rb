# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_assignments
#
#  id                :uuid             not null, primary key
#  assignable_type   :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  assignable_id     :uuid             not null
#  fleet_squadron_id :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_assignments_on_assignable         (assignable_type,assignable_id)
#  index_fleet_squadron_assignments_on_fleet_squadron_id  (fleet_squadron_id)
#  index_fleet_squadron_assignments_uniqueness            (fleet_squadron_id,assignable_type,assignable_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#
class FleetSquadronAssignment < ApplicationRecord
  belongs_to :fleet_squadron
  belongs_to :assignable, polymorphic: true

  validates :fleet_squadron_id, uniqueness: {scope: %i[assignable_type assignable_id]}

  def self.ransackable_attributes(_auth_object = nil)
    %w[fleet_squadron_id assignable_type assignable_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_squadron assignable]
  end
end
