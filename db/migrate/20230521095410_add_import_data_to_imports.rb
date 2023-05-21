class AddImportDataToImports < ActiveRecord::Migration[7.0]
  def change
    add_column :imports, :import_data, :text
  end
end
