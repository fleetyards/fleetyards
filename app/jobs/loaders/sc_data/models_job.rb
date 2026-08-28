# frozen_string_literal: true

module Loaders
  module ScData
    class ModelsJob < ::Loaders::BaseJob
      include FetchesParsedTree

      def perform
        version = ::ScData::Source.version

        import = Imports::ScData::ModelsImport.create(version:)

        import.start!

        fetch_parsed_tree!(version)

        loader = ::ScData::Loader::ModelsLoader.new

        loader.all

        import.update!(output: {"ModelsLoader" => loader.stats})

        report_unlisted_models(import)

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end

      # The load only ever iterates models that already exist, so a ship in the
      # game files with no row is invisible to it. This is what says so.
      #
      # Only a genuinely new entry is actionable, so the pile that has been
      # sitting undecided does not reopen an issue on every patch.
      private def report_unlisted_models(import)
        result = ::ScData::UnlistedModels.new.run

        AdminReport.deliver(
          task_type: "sc_data_unlisted_models",
          title: "Ships in the game files with no model (#{result[:new].size} new)",
          body: ::ScData::UnlistedModels.report_body(result),
          actionable: ::ScData::UnlistedModels.actionable?(result),
          record: import
        )
      end
    end
  end
end
