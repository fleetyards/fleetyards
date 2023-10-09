# frozen_string_literal: true

require "paints_importer"

module Loaders
  class PaintsImportJob < ::Loaders::BaseJob
    def perform
      results = ::PaintsImporter.new.run

      AdminMailer.paints_import_results(results).deliver_later
    end
  end
end
