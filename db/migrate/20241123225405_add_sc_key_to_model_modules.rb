class AddScKeyToModelModules < ActiveRecord::Migration[7.1]
  def change
    add_column :model_modules, :sc_key, :string
  end
end
