# frozen_string_literal: true

module Maintenance
  class PaintsImportTask < MaintenanceTasks::Task
    no_collection

    def process
      results = ::PaintsImporter.new.run

      AdminMailer.paints_import_results(results).deliver_later
    end
  end
end
