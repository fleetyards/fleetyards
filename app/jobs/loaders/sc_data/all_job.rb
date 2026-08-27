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

        # `to_h` rather than the bare return: a loader set that produced
        # nothing hands back nil, and the report still has to render.
        stats = ::ScData::Loader::BaseLoader.all.to_h

        # Kept on the import so the admin view of a load says what it did.
        # Otherwise the only record of a build that rewrote the catalogue, versus
        # one that changed nothing, is a log line nobody goes looking for.
        import.update!(output: stats)

        AdminReport.deliver(
          task_type: "sc_data_import",
          title: "sc_data Import Results (#{version})",
          body: results_body(version, stats),
          actionable: empty_catalogue?(stats),
          link: "/maintenance/imports",
          record: import
        )

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end

      private def results_body(version, stats)
        lines = ["## sc_data #{version}", ""]

        stats.each do |loader, counts|
          lines << "### #{loader}"
          lines << ""

          if counts.blank?
            lines << "- nothing written"
          else
            counts.sort.each do |name, buckets|
              lines << "- **#{name}**: #{buckets.map { |bucket, count| "#{bucket} #{count}" }.join(", ")}"
            end
          end

          lines << ""
        end

        lines.join("\n").strip
      end

      # A loader that wrote nothing and left nothing unchanged never saw its
      # catalogue - the failure that left Commodity and Equipment empty for a
      # week. Worth a human, unlike a build that simply changed little.
      private def empty_catalogue?(stats)
        stats.any? do |_loader, counts|
          counts.blank? || counts.values.all? { |buckets| buckets.values.sum.zero? }
        end
      end
    end
  end
end
