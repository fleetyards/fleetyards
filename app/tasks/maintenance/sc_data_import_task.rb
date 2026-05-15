# frozen_string_literal: true

module Maintenance
  class ScDataImportTask < MaintenanceTasks::Task
    no_collection

    def process
      version = Rails.configuration.sc_data[:version]

      return if Imports::ScData::AllImport.finished.exists?(version:)

      Loaders::ScData::AllJob.perform_async(version)
    end
  end
end
