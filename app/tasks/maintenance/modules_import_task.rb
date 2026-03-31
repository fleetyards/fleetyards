# frozen_string_literal: true

module Maintenance
  class ModulesImportTask < MaintenanceTasks::Task
    no_collection

    def process
      results = ::ModulesImporter.new.run

      AdminMailer.modules_import_results(results).deliver_later
    end
  end
end
