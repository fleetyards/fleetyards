class AddDataSlugToComponents < ActiveRecord::Migration[6.0]
  def change
    add_column :components, :data_slug, :string
  end
end
