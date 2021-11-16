class AddErkulIdentifierToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :erkul_identifier, :string
  end
end
