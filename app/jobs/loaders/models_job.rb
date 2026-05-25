# frozen_string_literal: true

module Loaders
  class ModelsJob < ::Loaders::BaseJob
    def perform(admin_user_id = nil)
      import = Imports::ModelsImport.create(admin_user_id:)

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
