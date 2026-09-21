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

          # Recorded before the load rather than after it, and from the tree on
          # disk rather than the bucket: this is the tree the loaders are about
          # to read. A load that then fails leaves the checksum on a record that
          # never finished, so `CheckJob` keeps seeing the work as outstanding.
          import.update!(tree_checksum: tree_checksum(source))

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

        report_unlisted_models(source, import)

        import.finish!
      rescue => e
        import.fail!
        import.update!(info: e.message)

        raise e
      end

      # Read out of the tree's own manifest rather than recomputed from its
      # files. `CheckJob` compares this against what the *parser* wrote, so
      # hashing it a second time here would make two producers for one value
      # and leave them free to disagree -- and a disagreement there is not
      # quiet: the tree check has no ceiling, so it would reload the whole of
      # sc_data every night, indefinitely.
      #
      # After `fetch_parsed_tree!` the manifest on disk is the bucket's own, so
      # the two are the same string by construction. Nil for a tree pushed
      # before checksums existed, and for a developer whose store is not
      # configured at all.
      private def tree_checksum(source)
        ::ScData::ParsedStore.new(source.environment).local_checksum
      end

      # The load only ever iterates models that already exist, so a ship in the
      # game files with no row is invisible to it. This is what says so.
      #
      # Here rather than in `Loaders::ScData::ModelsJob`, where it used to live:
      # nothing enqueues that job. `CheckJob` -- the only thing that triggers a
      # load, and only when a build has not been loaded yet -- enqueues this
      # one, and the admin trigger does too. So the report ran for the first
      # time in production only if somebody called it by hand.
      #
      # Inside the source, so a run reads the tree of the build it just loaded.
      #
      # Notification only. Every entry is decided on the admin ships list, which
      # carries the same pile and the buttons that clear it, so an issue opened
      # here only restates that list somewhere nobody acts on it -- and then has
      # to be closed by hand.
      #
      # The run always happens: it upserts what the export showed and retires
      # what it no longer does. Only a build that turned up something new is
      # worth a notification -- the undecided pile is on the ships list either
      # way, and a row per patch saying it is still there is noise.
      private def report_unlisted_models(source, import)
        result = ::ScData::Source.with(source) { ::ScData::UnlistedModels.new.run }

        return unless ::ScData::UnlistedModels.actionable?(result)

        AdminReport.deliver(
          task_type: "sc_data_unlisted_models",
          title: "Ships in the game files with no model (#{result[:new].size} new)",
          body: ::ScData::UnlistedModels.report_body(result, source),
          actionable: true,
          link: "/models/unlisted/",
          record: import,
          github_issue: false
        )
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
