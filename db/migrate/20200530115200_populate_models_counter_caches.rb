# frozen_string_literal: true

class PopulateModelsCounterCaches < ActiveRecord::Migration[6.0]
  def up
    Model.find_each do |model|
      Model.reset_counters(model.id, :paints)
      Model.reset_counters(model.id, :images)
      Model.reset_counters(model.id, :videos)
      Model.reset_counters(model.id, :module_hardpoints)
      Model.reset_counters(model.id, :upgrade_kits)
    end

    Station.find_each do |station|
      Station.reset_counters(station.id, :images)
    end
  end
end
