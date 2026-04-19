class AddScKeyToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :sc_key, :string
  end
end
