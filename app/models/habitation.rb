# frozen_string_literal: true

# == Schema Information
#
# Table name: habitations
#
#  id              :uuid             not null, primary key
#  habitation_name :string
#  habitation_type :integer
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  station_id      :uuid
#
# Indexes
#
#  habitations_station_id_index     (station_id)
#  index_habitations_on_station_id  (station_id)
#
class Habitation < ApplicationRecord
  belongs_to :station

  enum habitation_type: {container: 0, small_apartment: 1, medium_apartment: 2, large_apartment: 3, suite: 4}
  ransacker :habitation_type, formatter: proc { |v| Habitation.habitation_types[v] } do |parent|
    parent.table[:habitation_type]
  end

  validates :habitation_type, presence: true

  def habitation_type_label
    Habitation.human_enum_name(:habitation_type, habitation_type)
  end
end
