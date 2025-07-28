class AddSourceToHardpoints < ActiveRecord::Migration[7.1]
  def change
    add_column :hardpoints, :source, :integer
  end
end
