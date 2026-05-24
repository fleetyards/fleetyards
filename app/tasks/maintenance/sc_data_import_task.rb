# frozen_string_literal: true

module Maintenance
  class ScDataImportTask < MaintenanceTasks::Task
    no_collection

    attribute :force, :boolean, default: false

    def process
      version = Rails.configuration.sc_data[:version]

      return if !force && Imports::ScData::AllImport.finished.exists?(version:)

      Loaders::ScData::AllJob.perform_async(version)
    end
  end
end
