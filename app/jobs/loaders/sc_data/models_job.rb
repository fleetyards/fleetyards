# frozen_string_literal: true

module Loaders
  module ScData
    class ModelsJob < ::Loaders::BaseJob
      def perform
        version = Rails.configuration.app.sc_data_sc_version

        import = Imports::ScData::ModelsImport.create(version:)

        import.start!

        loader = ::ScData::ModelsLoader.new(sc_version: version)

        loader.run

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
