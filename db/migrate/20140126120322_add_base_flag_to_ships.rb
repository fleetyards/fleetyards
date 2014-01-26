class AddBaseFlagToShips < ActiveRecord::Migration
  def change
    add_column :ships, :is_base, :boolean, null: false, default: false
  end
end
