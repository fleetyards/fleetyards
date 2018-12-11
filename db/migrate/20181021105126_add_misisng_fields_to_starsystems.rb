class AddMisisngFieldsToStarsystems < ActiveRecord::Migration[5.2]
  def change
    add_column :starsystems, :rsi_id, :integer
    add_column :starsystems, :code, :string
    add_column :starsystems, :position_x, :string
    add_column :starsystems, :position_y, :string
    add_column :starsystems, :position_z, :string
    add_column :starsystems, :status, :string
    add_column :starsystems, :last_updated_at, :datetime
    add_column :starsystems, :system_type, :string
    add_column :starsystems, :aggregated_size, :string
    add_column :starsystems, :aggregated_population, :integer
    add_column :starsystems, :aggregated_economy, :integer
    add_column :starsystems, :aggregated_danger, :integer
    add_column :starsystems, :hidden, :boolean, default: true
    add_column :starsystems, :description, :text
    add_column :starsystems, :map_y, :string
    add_column :starsystems, :map_x, :string

    add_column :stations, :description, :text
    add_column :stations, :celestial_object_id, :uuid
    add_index(:stations, :celestial_object_id)
  end
end
