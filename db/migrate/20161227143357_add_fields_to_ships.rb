class AddFieldsToShips < ActiveRecord::Migration
  def change
    add_column :ships, :production_state, :string
    add_column :ships, :production_note, :string
    add_column :ships, :focus, :string
  end
end
