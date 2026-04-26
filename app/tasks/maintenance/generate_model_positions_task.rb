# frozen_string_literal: true

module Maintenance
  class GenerateModelPositionsTask < MaintenanceTasks::Task
    def collection
      Model.where(in_game: true)
    end

    def count
      collection.count
    end

    def process(model)
      ModelPosition.generate_for_model!(model)
    end
  end
end
