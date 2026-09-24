# frozen_string_literal: true

class AddRankToFleetSquadrons < ActiveRecord::Migration[8.0]
  include Lexorank

  class Squadron < ActiveRecord::Base
    self.table_name = "fleet_squadrons"
  end

  def up
    # Byte order, because a lexorank is compared character by character: under
    # the database's locale collation "g" sorts before "U", and the next rank
    # handed out would repeat one already taken.
    add_column :fleet_squadrons, :rank, :text, collation: "C"

    # The order they were listed in until now, so nothing moves on the way in.
    Squadron.distinct.pluck(:fleet_id).each do |fleet_id|
      previous = nil

      Squadron.where(fleet_id:).order(:name).each do |squadron|
        previous = value_between(previous, nil)
        squadron.update_column(:rank, previous)
      end
    end

    change_column_null :fleet_squadrons, :rank, false
    add_index :fleet_squadrons, %i[fleet_id rank], unique: true
  end

  def down
    remove_index :fleet_squadrons, %i[fleet_id rank]
    remove_column :fleet_squadrons, :rank
  end
end
