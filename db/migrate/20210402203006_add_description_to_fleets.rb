class AddDescriptionToFleets < ActiveRecord::Migration[6.1]
  def change
    add_column :fleets, :description, :text
  end
end
