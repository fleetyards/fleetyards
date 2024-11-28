class AddScDataFieldsToManufacturers < ActiveRecord::Migration[7.1]
  def change
    add_column :manufacturers, :sc_ref, :string
  end
end
