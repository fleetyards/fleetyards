# frozen_string_literal: true

# A ship named as fitting a berth, beyond what the berth's class says.
#
# The class answers for the ordinary case; this is for the one somebody checked
# in game and found to differ. Naming a ship that the class already covers is
# allowed rather than refused -- it is a statement about that ship, and a berth
# whose class changes later keeps it.
class DockAddition < ApplicationRecord
  belongs_to :dock, touch: true
  belongs_to :model

  validates :model_id, uniqueness: {scope: :dock_id}

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at dock_id id id_value model_id updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[dock model]
  end
end
