class AddGalleryFieldsToImages < ActiveRecord::Migration[7.2]
  def change
    add_column :images, :gallery_name, :string
    add_column :images, :gallery_slug, :string
  end
end
