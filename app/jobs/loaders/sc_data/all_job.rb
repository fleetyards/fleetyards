# frozen_string_literal: true

module Loaders
  module ScData
    class AllJob < ::Loaders::BaseJob
      include FetchesParsedTree

      def perform(version = nil, admin_user_id = nil)
        version ||= ::ScData::Source.version

        import = Imports::ScData::AllImport.create(version:, admin_user_id:)

        import.start!

        fetch_parsed_tree!(version)

        # Kept on the import so the admin view of a load says what it did.
        # Otherwise the only record of a build that rewrote the catalogue, versus
        # one that changed nothing, is a log line nobody goes looking for.
        import.update!(output: ::ScData::Loader::BaseLoader.all)

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end
    end
  end
end
