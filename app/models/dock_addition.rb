# frozen_string_literal: true

# A ship named as fitting a berth, beyond what the berth's class says.
#
# The class answers for the ordinary case; this is for the one somebody checked
# in game and found to differ. Naming a ship that the class already covers is
# allowed rather than refused -- it is a statement about that ship, and a berth
# whose class changes later keeps it.
# == Schema Information
#
# Table name: dock_additions
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dock_id    :uuid             not null
#  model_id   :uuid             not null
#
# Indexes
#
#  index_dock_additions_on_dock_id               (dock_id)
#  index_dock_additions_on_dock_id_and_model_id  (dock_id,model_id) UNIQUE
#  index_dock_additions_on_model_id              (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (dock_id => docks.id)
#  fk_rails_...  (model_id => models.id)
#
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
