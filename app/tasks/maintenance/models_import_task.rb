# frozen_string_literal: true

module Maintenance
  class ModelsImportTask < MaintenanceTasks::Task
    no_collection

    def process
      import = Imports::ModelsImport.create

      import.start!

      ::Rsi::ModelsLoader.new.all

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
