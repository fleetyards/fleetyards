# frozen_string_literal: true

class AddRankToVehicles < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Lexorank compares ranks byte by byte. Under the database's en_US collation
    # "a" sorts before "B" and punctuation is skipped at the first level, so the
    # midpoints it computes would land out of order.
    add_column :vehicles, :rank, :text, collation: "C"

    add_index :vehicles,
      %i[user_id rank],
      unique: true,
      algorithm: :concurrently
  end
end
