class AddMissingIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index(:auth_tokens, :user_id)
    add_index(:components, :manufacturer_id)
    add_index(:docks, :station_id)
    add_index(:hangar_groups, :user_id)
    add_index(:hardpoints, :model_id)
    add_index(:hardpoints, :component_id)
    add_index(:images, :gallery_id)
    add_index(:model_additions, :model_id)
    add_index(:planets, :starsystem_id)
    add_index(:planets, :planet_id)
    add_index(:shop_commodities, :shop_id)
    add_index(:shop_commodities, :commodity_item_id)
    add_index(:shops, :station_id)
    add_index(:stations, :planet_id)
    add_index(:task_forces, :hangar_group_id)
    add_index(:task_forces, :vehicle_id)
    add_index(:trade_commodities, :trade_hub_id)
    add_index(:vehicles, :user_id)
    add_index(:vehicles, :model_id)
    add_index(:videos, :model_id)
  end
end
