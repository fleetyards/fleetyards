# frozen_string_literal: true

class Habitation < ApplicationRecord
  belongs_to :station

  enum habitation_type: { container: 0, small_apartment: 1, medium_apartment: 2, large_apartment: 3, suite: 4 }
  ransacker :habitation_type, formatter: proc { |v| Habitation.habitation_types[v] } do |parent|
    parent.table[:habitation_type]
  end

  validates :habitation_type, :station_id, presence: true

  def habitation_type_label
    Habitation.human_enum_name(:habitation_type, habitation_type)
  end
end
