class AddHoloColoredToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :holo_colored, :boolean, default: false
  end
end
