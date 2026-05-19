class AddRefuelBoomToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :refuel_boom, :string
  end
end
