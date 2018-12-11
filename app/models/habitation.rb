# frozen_string_literal: true

class Habitation < ApplicationRecord
  belongs_to :station

  enum habitation_type: %i[container small_apartment medium_apartment large_apartment suite]
  ransacker :habitation_type, formatter: proc { |v| Habitation.habitation_types[v] } do |parent|
    parent.table[:habitation_type]
  end

  validates :habitation_type, :station_id, presence: true

  def habitation_type_label
    Habitation.human_enum_name(:habitation_type, habitation_type)
  end
end
