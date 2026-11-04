# frozen_string_literal: true

module Maintenance
  # Collapses the manufacturers the sc_data loader duplicated before it learned
  # to reuse a name it already has, and corrects the names the export mislabelled.
  #
  # A maintenance task rather than a data migration: it destroys rows and cannot
  # be undone, and `data:migrate` runs unattended on every deploy. Here it is run
  # deliberately, once per environment, with `dry_run` first.
  class DedupeManufacturersTask < MaintenanceTasks::Task
    no_collection

    # The rows the loader created under a name the export got wrong. Applied here
    # rather than by the loader, which deliberately never rewrites `name` because
    # a curated one beats the game's -- these are the exceptions to that, so they
    # are named explicitly rather than taken from the parsed data wholesale.
    CORRECTIONS = {
      "MXOX" => "maxOx",
      "PRAR" => "Preacher Armaments",
      "FSKI" => "Firestorm Kinetics"
    }.freeze

    # Records that are not a company. TRAS and GHEX are copies of another
    # manufacturer, logo included, that nothing in the export references; GEND
    # and GENF are the generic maker a drink or a food carryable is filed under,
    # and both name themselves "Consumable", so loading them would put one row by
    # that name in the table holding both codes.
    #
    # Kept in step with the `skip: true` entries in the parser overrides -- a
    # fresh import and a cleaned table have to agree about what a code is -- and
    # dropped only while nothing points at them.
    DROPPED_CODES = %w[TRAS GHEX GEND GENF].freeze

    # One company under two codes, read as `export code => the code that stays`.
    #
    # MISC is the row the RSI matrix created in 2014 and every ship hangs off;
    # MIS is what the export's `scitemmanufacturer` record calls the same
    # company, and the loader had nothing to match it on -- neither the code nor
    # the slug "Musashi Industrial & Starflight Concern" produces -- so it minted
    # a second row for the items. The table already records the pair: MISC
    # carries `code_mapping` "MIS" and the full name in `long_name`.
    #
    # Named here rather than read from that column because the merge destroys
    # rows: which pairs collapse should be visible in a diff and pinned by a
    # test, not taken from a field nothing else reads and no admin can see.
    #
    # KRIG is the RSI matrix's row and holds the ships; KRI is the export's, which
    # misspells it "Kruger Intergalatic" in the row it first created.
    ALIASED_CODES = {"MIS" => "MISC", "KRI" => "KRIG"}.freeze

    # Holds only equipment the export names no maker for. It carries no sc_ref, so
    # no load could have filed anything here on purpose: a nil ref used to match
    # the first row without one, and this is the row that came first.
    MISFILED_SLUGS = %w[gallenson-tactical].freeze

    # Rows from before the export with no code, no ref and nothing pointing at
    # them, mostly an older spelling of a maker that has its own row now
    # ("Max Ox", "Seal Corp."), some with the name still HTML-escaped. The real
    # Gallenson is `gallenson-tactical-systems`.
    #
    # Talon Weapon Systems and Xi'An look the same but are left out: one holds an
    # uploaded logo and the other an RSI id.
    ABANDONED_SLUGS = %w[
      9x7 a-r amon-amp-reese-co associated-science-development escar
      gallenson-tactical grindstone-boots hawksworths juno-starwerks
      klaus-amp-werner max-ox muymuy nova
      ph-ph-associated-science-and-development quirinus-tech seal-corp stegman-s
      thermyte-lightfire tyler-design vanduul-components-generic wen-cassel
    ].freeze

    # Left on by default so an accidental run reports instead of destroying.
    attribute :dry_run, :boolean, default: true

    def process
      dry_run ? report_plan : apply
    end

    private def apply
      result = deduplicator(logger: method(:log)).call

      log "renamed #{result.renamed.size}, dropped #{result.dropped.size}, " \
          "aliased #{result.aliased.size}, merged #{result.merged.size} slugs, " \
          "released #{result.released.size}, abandoned #{result.abandoned.size}, " \
          "icons cleared #{result.icons_cleared.size}"
    end

    private def report_plan
      plan = deduplicator.plan

      plan[:log].each { |line| log line }

      log "manufacturers: #{plan[:before]} -> #{plan[:after]}"
      log "renamed #{plan[:renamed].size}, dropped #{plan[:dropped].size}, " \
          "aliased #{plan[:aliased].size}, merged #{plan[:merged].size} slugs, " \
          "released #{plan[:released].size}, abandoned #{plan[:abandoned].size}, " \
          "icons cleared #{plan[:icons_cleared].size}"
      log "records left without a manufacturer: #{plan[:orphaned]}"
      log "dry run -- rolled back, no rows were changed"
    end

    private def deduplicator(logger: nil)
      ::Manufacturers::Deduplicator.new(
        corrections: CORRECTIONS,
        dropped_codes: DROPPED_CODES,
        aliased_codes: ALIASED_CODES,
        misfiled_slugs: MISFILED_SLUGS,
        abandoned_slugs: ABANDONED_SLUGS,
        placeholder_icon: ::ScData::Parser::ManufacturersParser::PLACEHOLDER_ICON,
        placeholder_icon_keepers: ::ScData::Parser::ManufacturersParser::PLACEHOLDER_ICON_KEEPERS,
        logger:
      )
    end

    # The task's log is its output in the UI, which is stdout for this engine.
    private def log(message)
      puts message
    end
  end
end
