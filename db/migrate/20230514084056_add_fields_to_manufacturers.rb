class AddFieldsToManufacturers < ActiveRecord::Migration[7.0]
  def change
    add_column :manufacturers, :long_name, :string
    add_column :manufacturers, :code_mapping, :string
  end
end
