class ReplaceLoadoutUrlsWithSingleUrl < ActiveRecord::Migration[7.2]
  def up
    add_column :vehicle_loadouts, :url, :string

    execute <<~SQL
      UPDATE vehicle_loadouts
      SET url = COALESCE(erkul_url, spviewer_url)
      WHERE erkul_url IS NOT NULL OR spviewer_url IS NOT NULL
    SQL

    remove_column :vehicle_loadouts, :erkul_url
    remove_column :vehicle_loadouts, :spviewer_url
  end

  def down
    add_column :vehicle_loadouts, :erkul_url, :string
    add_column :vehicle_loadouts, :spviewer_url, :string

    execute <<~SQL
      UPDATE vehicle_loadouts
      SET erkul_url = url
      WHERE url LIKE '%erkul%'
    SQL

    execute <<~SQL
      UPDATE vehicle_loadouts
      SET spviewer_url = url
      WHERE url LIKE '%spviewer%'
    SQL

    remove_column :vehicle_loadouts, :url
  end
end
