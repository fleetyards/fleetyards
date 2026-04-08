# frozen_string_literal: true

module Maintenance
  class TouchModelsTask < MaintenanceTasks::Task
    def collection
      Model.all
    end

    def count
      collection.count
    end

    def process(model)
      model.touch
    end
  end
end
