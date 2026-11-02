class AddAttachPointsToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :equipment, :attach_points, :jsonb
    add_column :components, :attach_points, :jsonb
  end
end
