# frozen_string_literal: true

class CompareFleetRoleRanksByByte < ActiveRecord::Migration[8.1]
  # Lexorank computes midpoints by byte value. Under the database's en_US
  # collation "a" sorts before "B" and punctuation is skipped at the first
  # level, so a role placed between two others could land out of order.
  def up
    change_column :fleet_roles, :rank, :text, collation: "C"
  end

  def down
    change_column :fleet_roles, :rank, :text
  end
end
