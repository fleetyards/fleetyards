# frozen_string_literal: true

class AddDefaultOutfitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :default_outfit, type: :uuid, foreign_key: {to_table: :outfits, on_delete: :nullify}
  end
end
