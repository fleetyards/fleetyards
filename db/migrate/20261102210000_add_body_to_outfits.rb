class AddBodyToOutfits < ActiveRecord::Migration[8.1]
  def change
    add_column :outfits, :body, :string, null: false, default: "male"
  end
end
