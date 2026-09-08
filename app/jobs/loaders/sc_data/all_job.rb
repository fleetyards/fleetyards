# frozen_string_literal: true

module Loaders
  module ScData
    class AllJob < ::Loaders::BaseJob
      include FetchesParsedTree

      def perform(version = nil, admin_user_id = nil, environment = nil)
        source = source_for(version, environment)

        import = Imports::ScData::AllImport.create(version: source.version, admin_user_id:)

        import.start!

        # Everything the load touches resolves its build from `ScData::Source`,
        # so the whole of it runs inside the source rather than each loader
        # being handed a version -- the seam #4590 added, and the reason
        # `fetch_parsed_tree!` reaches for the right environment's tree without
        # being told.
        #
        # `to_h` rather than the bare return: a loader set that produced
        # nothing hands back nil, and the report still has to render.
        stats = ::ScData::Source.with(source) do
          fetch_parsed_tree!(source.version)

          ::ScData::Loader::BaseLoader.all.to_h
        end

        # Kept on the import so the admin view of a load says what it did.
        # Otherwise the only record of a build that rewrote the catalogue, versus
        # one that changed nothing, is a log line nobody goes looking for.
        import.update!(output: stats)

        AdminReport.deliver(
          task_type: "sc_data_import",
          title: "sc_data Import Results (#{source})",
          body: results_body(source, stats),
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

      # The build to load. A version and an environment name it exactly; either
      # one alone falls back to the configured source, which is what the admin
      # trigger hands over and what a job enqueued before this shipped carries.
      private def source_for(version, environment)
        return ::ScData::Source.current if version.blank? && environment.blank?

        ::ScData::Source.new(
          version: version.presence || ::ScData::Source.version,
          environment: environment.presence || ::ScData::Source.environment
        )
      end

      private def results_body(source, stats)
        lines = ["## sc_data #{source}", ""]

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
