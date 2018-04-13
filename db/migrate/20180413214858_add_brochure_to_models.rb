class AddBrochureToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :brochure, :string
  end
end
