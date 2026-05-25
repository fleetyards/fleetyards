# frozen_string_literal: true

module Loaders
  module ScData
    class AllJob < ::Loaders::BaseJob
      def perform(version = nil, admin_user_id = nil)
        version ||= Rails.configuration.sc_data[:version]

        import = Imports::ScData::AllImport.create(version:, admin_user_id:)

        import.start!

        ::ScData::Loader::BaseLoader.all

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
