# frozen_string_literal: true

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
#  fk_rails_...  (dock_id => docks.id) ON DELETE => cascade
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :dock_addition do
    dock
    model
  end
end
