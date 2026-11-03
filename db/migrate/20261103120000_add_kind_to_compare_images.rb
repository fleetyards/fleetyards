class AddKindToCompareImages < ActiveRecord::Migration[8.1]
  def change
    add_column :compare_images, :kind, :string, null: false, default: "models"

    remove_index :compare_images, :slug_set, unique: true
    add_index :compare_images, [:kind, :slug_set], unique: true

    remove_index :compare_images, :share_key, unique: true, where: "(share_key IS NOT NULL)"
    add_index :compare_images, [:kind, :share_key], unique: true, where: "(share_key IS NOT NULL)"
  end
end
