# frozen_string_literal: true

module Maintenance
  # Creates the ships the RSI ship matrix does not list, for a database that
  # already exists.
  #
  # `db/seeds` covers a fresh one, but running it against a live database means
  # loading every seed file, so the ships that go missing after an import are
  # topped up from here instead.
  class SeedManualModelsTask < MaintenanceTasks::Task
    def collection
      ::Models::ManualRecords::MODELS
    end

    def count
      collection.size
    end

    def process(definition)
      model = ::Models::ManualRecords.upsert_model(definition)

      puts "#{model.name} (#{model.manufacturer&.name})" if model.previously_new_record?
    end
  end
end
