# frozen_string_literal: true

class AddShortDescriptionToFleetSquadronFlights < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_squadron_flights, :short_description, :text
  end
end
