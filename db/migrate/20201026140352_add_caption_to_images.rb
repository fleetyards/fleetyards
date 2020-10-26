class AddCaptionToImages < ActiveRecord::Migration[6.0]
  def change
    add_column :images, :caption, :string
  end
end
