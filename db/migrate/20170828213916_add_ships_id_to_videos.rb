class AddShipsIdToVideos < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :ship_id, :uuid
  end
end
