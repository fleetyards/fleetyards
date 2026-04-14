class AddLocationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :location, :string
    add_column :users, :latitude, :decimal, precision: 10, scale: 6
    add_column :users, :longitude, :decimal, precision: 10, scale: 6
  end
end
