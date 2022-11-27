class MigratePapertrailToJson < ActiveRecord::Migration[6.1]
  def change
    rename_column :versions, :object, :old_object
    rename_column :versions, :object_changes, :old_object_changes
    add_column :versions, :object, :json
    add_column :versions, :object_changes, :json
  end
end

# PaperTrail::Version.where.not(old_object: nil).find_each do |version|
#   version.update_columns(
#     old_object: nil,
#     object: YAML.unsafe_load(version.old_object)
#   )
# end

# PaperTrail::Version.where.not(old_object_changes: nil).find_each do |version|
#   version.update_columns(
#     old_object_changes: nil,
#     object_changes: YAML.unsafe_load(version.old_object_changes),
#   )
# end
