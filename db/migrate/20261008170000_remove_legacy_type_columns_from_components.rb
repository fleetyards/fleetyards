# frozen_string_literal: true

# `category` replaced both columns, and no build the game still ships carries
# either. The release before this one stopped selecting them (`ignored_columns`),
# so the containers still serving it are unaffected by the pre-deploy migration.
class RemoveLegacyTypeColumnsFromComponents < ActiveRecord::Migration[8.1]
  def change
    remove_index :component_builds, %i[environment item_type],
      name: "index_component_builds_on_environment_and_item_type"
    remove_index :component_builds, %i[environment component_class],
      name: "index_component_builds_on_environment_and_component_class"

    remove_column :component_builds, :item_type, :string
    remove_column :component_builds, :component_class, :string
    remove_column :components, :item_type, :string
    remove_column :components, :component_class, :string
  end
end
