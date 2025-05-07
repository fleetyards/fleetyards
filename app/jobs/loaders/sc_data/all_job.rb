# frozen_string_literal: true

module Loaders
  module ScData
    class AllJob < ::Loaders::BaseJob
      def perform
        version = Rails.configuration.app.sc_data_sc_version

        import = Imports::ScData::AllImport.create(version:)

        import.start!

        ::ScData::BaseLoader.run_all(sc_version: version)

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
