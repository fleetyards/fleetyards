# frozen_string_literal: true

class AddDedicationPlaqueToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :dedication, :text
    add_column :vehicles, :launched_on, :date
    add_column :vehicles, :launch_port, :string
    add_reference :vehicles, :launch_port_location, type: :uuid, index: true,
      foreign_key: {to_table: :locations, on_delete: :nullify}
    add_column :vehicles, :affiliation, :string
    add_column :vehicles, :alignment, :string
  end
end
