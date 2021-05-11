class AddHoloToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :holo, :string
  end
end
