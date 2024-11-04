# frozen_string_literal: true

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    def perform
      import = Imports::ModelsImport.create

      import.start!

      ::Rsi::ModelsLoader
        .new(vat_percent: Rails.configuration.rsi.vat_percent)
        .all

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
