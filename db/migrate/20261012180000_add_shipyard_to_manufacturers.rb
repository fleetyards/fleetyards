# frozen_string_literal: true

class AddShipyardToManufacturers < ActiveRecord::Migration[8.1]
  def change
    add_column :manufacturers, :shipyard, :string
    add_reference :manufacturers, :shipyard_location, type: :uuid, index: true,
      foreign_key: {to_table: :locations, on_delete: :nullify}
  end
end
