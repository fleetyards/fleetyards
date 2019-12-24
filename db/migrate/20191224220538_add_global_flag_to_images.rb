class AddGlobalFlagToImages < ActiveRecord::Migration[5.2]
  def change
    add_column :images, :global, :boolean, default: true
  end
end
