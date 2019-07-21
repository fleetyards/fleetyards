class RemoveFallbackFieldsFromModel < ActiveRecord::Migration[5.2]
  def up
    remove_column :models, :fallback_beam
    remove_column :models, :fallback_length
    remove_column :models, :fallback_height
    remove_column :models, :fallback_mass
    remove_column :models, :fallback_cargo
    remove_column :models, :fallback_scm_speed
    remove_column :models, :fallback_afterburner_speed
    remove_column :models, :fallback_cruise_speed
    remove_column :models, :fallback_min_crew
    remove_column :models, :fallback_max_crew
    rename_column :models, :fallback_pledge_price, :last_pledge_price
  end

  def down
    rename_column :models, :last_pledge_price, :fallback_pledge_price
    remove_column :models, :fallback_min_crew
    remove_column :models, :fallback_max_crew
    remove_column :models, :fallback_cruise_speed
    remove_column :models, :fallback_afterburner_speed
    remove_column :models, :fallback_scm_speed
    remove_column :models, :fallback_cargo
    remove_column :models, :fallback_mass
    remove_column :models, :fallback_height
    remove_column :models, :fallback_length
    remove_column :models, :fallback_beam
  end
end
