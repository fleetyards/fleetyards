# frozen_string_literal: true

module Loaders
  class ModelJob < ::Loaders::BaseJob
    def perform(rsi_id)
      import = Imports::ModelImport.create(input: {rsi_id: rsi_id})

      import.start!

      ::Rsi::ModelsLoader.new.one(rsi_id)

      import.finish!
    rescue => e
      import.fail!
      import.update!(info: e.message)

      raise e
    end
  end
end
