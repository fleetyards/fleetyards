class AddImportFieldToImports < ActiveRecord::Migration[7.0]
  def change
    add_column :imports, :import, :string
  end
end
