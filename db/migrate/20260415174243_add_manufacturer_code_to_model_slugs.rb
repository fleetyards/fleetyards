# frozen_string_literal: true

class AddManufacturerCodeToModelSlugs < ActiveRecord::Migration[8.1]
  def up
    add_column :models, :legacy_slug, :string
    add_index :models, :legacy_slug

    Model.includes(:manufacturer).find_each do |model|
      next if model.manufacturer.blank?

      old_slug = model.slug
      new_slug = "#{model.manufacturer.code.downcase}-#{old_slug}"
      model.update_columns(legacy_slug: old_slug, slug: new_slug)
    end

    remove_index :models, :name
    add_index :models, [:manufacturer_id, :name], unique: true
  end

  def down
    Model.where.not(legacy_slug: nil).find_each do |model|
      model.update_columns(slug: model.legacy_slug, legacy_slug: nil)
    end

    remove_index :models, [:manufacturer_id, :name]
    add_index :models, :name

    remove_index :models, :legacy_slug
    remove_column :models, :legacy_slug
  end
end
