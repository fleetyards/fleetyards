class AddPlayerOwnableToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :player_ownable, :boolean, default: true, null: false
  end
end
