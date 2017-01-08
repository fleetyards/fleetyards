class RemoveImageFromShips < ActiveRecord::Migration
  class Ship < ActiveRecord::Base
    mount_uploader :image, ImageUploader
  end

  def up
    Ship.find_each do |ship|
      ship.remove_image!
      ship.save
    end

    remove_column :ships, :image
  end

  def down
    add_column :ships, :image, :string
  end
end
