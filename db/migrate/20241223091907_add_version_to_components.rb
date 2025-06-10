class AddVersionToComponents < ActiveRecord::Migration[7.1]
  def change
    add_column :components, :version, :string
  end
end
