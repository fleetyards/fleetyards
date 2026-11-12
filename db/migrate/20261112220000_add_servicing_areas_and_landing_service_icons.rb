# frozen_string_literal: true

class AddServicingAreasAndLandingServiceIcons < ActiveRecord::Migration[8.1]
  def change
    create_table :landing_services, id: :uuid do |t|
      t.string :key, null: false
      t.timestamps
    end
    add_index :landing_services, :key, unique: true

    %i[models model_builds].each { |table| add_column table, :servicing_areas, :jsonb }
    add_column :models, :servicing_area_names, :jsonb, null: false, default: {}
  end
end
