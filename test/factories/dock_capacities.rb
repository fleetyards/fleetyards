# frozen_string_literal: true

# == Schema Information
#
# Table name: dock_capacities
#
#  id         :uuid             not null, primary key
#  display    :boolean          default(FALSE), not null
#  ladder     :integer          not null
#  quantity   :integer          default(1), not null
#  size       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dock_id    :uuid             not null
#
# Indexes
#
#  index_dock_capacities_on_dock_id                      (dock_id)
#  index_dock_capacities_on_dock_id_and_ladder_and_size  (dock_id,ladder,size) UNIQUE
#  index_dock_capacities_on_one_display_per_dock         (dock_id) UNIQUE WHERE display
#
# Foreign Keys
#
#  fk_rails_...  (dock_id => docks.id)
#
FactoryBot.define do
  factory :dock_capacity do
    dock
    ladder { :ship }
    size { "small" }
    quantity { 1 }
    display { false }
  end
end
