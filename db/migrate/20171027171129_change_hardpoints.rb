class ChangeHardpoints < ActiveRecord::Migration[5.1]
  def change
    Component.destroy_all
    Hardpoint.destroy_all

    remove_column :components, :enabled, :boolean
    remove_column :manufacturers, :enabled, :boolean
    remove_column :models, :enabled, :boolean
    remove_column :videos, :enabled, :boolean

    add_column :manufacturers, :code, :string

    remove_column :hardpoints, :hardpoint_class, :string
    remove_column :hardpoints, :rating, :integer
    remove_column :hardpoints, :max_size, :integer
    remove_column :hardpoints, :rsi_id, :integer
    remove_column :hardpoints, :category_id, :uuid
    remove_column :hardpoints, :name, :string

    add_column :hardpoints, :component_class, :string
    add_column :hardpoints, :hardpoint_type, :string
    add_column :hardpoints, :mounts, :integer
    add_column :hardpoints, :size, :string
    add_column :hardpoints, :details, :string
    add_column :hardpoints, :category, :string

    remove_column :components, :component_type, :string
    remove_column :components, :rsi_id, :integer
    remove_column :components, :category_id, :uuid

    add_column :components, :manufacturer_id, :uuid
    add_column :components, :component_class, :string

    reversible do |change|
      change.up do
        drop_table :component_categories if ActiveRecord::Base.connection.table_exists? 'component_categories'
      end
    end
  end
end
