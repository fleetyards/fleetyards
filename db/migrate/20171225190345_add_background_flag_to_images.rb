class AddBackgroundFlagToImages < ActiveRecord::Migration[5.1]
  def change
    add_column :images, :background, :boolean, default: true
  end
end
