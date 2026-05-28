# frozen_string_literal: true

class AddShareColumnsToCompareImages < ActiveRecord::Migration[8.1]
  def change
    add_column :compare_images, :share_key, :string
    add_column :compare_images, :short_code, :string

    add_index :compare_images, :share_key, unique: true, where: "share_key IS NOT NULL"
    add_index :compare_images, :short_code, unique: true, where: "short_code IS NOT NULL"
  end
end
