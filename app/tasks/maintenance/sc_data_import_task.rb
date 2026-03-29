# frozen_string_literal: true

module Maintenance
  class ScDataImportTask < MaintenanceTasks::Task
    no_collection

    def process
      version = Rails.configuration.app.sc_data[:version]

      import = Imports::ScData::AllImport.create(version:)

      import.start!

      ::ScData::Loader::BaseLoader.all(sc_version: version)

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
