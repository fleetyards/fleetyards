class AddFallbackFieldsToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :fallback_beam, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_length, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_height, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_mass, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_cargo, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_scm_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_afterburner_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_cruise_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    add_column :models, :fallback_min_crew, :integer, default: nil, null: true
    add_column :models, :fallback_max_crew, :integer, default: nil, null: true
    add_column :models, :fallback_price, :decimal, precision: 15, scale: 2, default: nil, null: true
  end
end
