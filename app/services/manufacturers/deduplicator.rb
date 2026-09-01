# frozen_string_literal: true

module Manufacturers
  # Collapses the manufacturers the sc_data loader duplicated before it learned
  # to reuse a name it already has.
  #
  # The export labels several records with another manufacturer's name -- four
  # of its codes resolve to "Aegis Dynamics" -- and the loader only matched a row
  # without an sc_ref, so every new ref minted a row. The parser no longer
  # produces those names and the loader no longer creates the rows, but the ones
  # already in the table have to be brought together, and the loader never
  # rewrites `name` so they cannot fix themselves.
  #
  # A second kind no grouping can see: the same company under two codes and two
  # names, where neither the code nor the slug they produce match. The RSI matrix
  # calls Musashi Industrial & Starflight Concern "MISC" while the export files
  # it under "MIS", so the two rows share nothing to group on and have to be
  # named as a pair.
  class Deduplicator
    # Tables carrying `manufacturer_id`. Checked against the schema on the way in
    # so a table added later fails loudly here rather than quietly orphaning its
    # rows.
    ASSOCIATED_MODELS = [
      Model, Component, ComponentBuild, Equipment, EquipmentBuild, ModelModule
    ].freeze

    Result = Struct.new(:renamed, :dropped, :aliased, :merged)

    def initialize(corrections: {}, dropped_codes: [], aliased_codes: {}, logger: nil)
      @corrections = corrections
      @dropped_codes = dropped_codes
      @aliased_codes = aliased_codes
      @logger = logger
      @result = Result.new([], [], [], [])
    end

    # All or nothing. The phases feed each other -- a correction takes a row out
    # of a group before the merge looks at it -- so a failure partway through
    # would leave some names corrected, some placeholders gone and some collisions
    # still standing, which is a worse table to recover from than the one we
    # started with. Nothing here is undoable once committed.
    #
    # The aliases go before the slug merge so a pair named there is settled while
    # both rows are still identified by their own code, rather than depending on
    # which of them a slug group would have left standing.
    #
    # requires_new so it is a savepoint inside a surrounding transaction: #plan
    # wraps it in one to roll the whole thing back, and the tests run in one.
    def call
      assert_every_association_covered!

      Manufacturer.transaction(requires_new: true) do
        apply_corrections
        drop_records
        merge_aliases
        merge_collisions
      end

      @result
    end

    # Reports what #call would do, so the same decisions can be reviewed on
    # production before anything is destroyed.
    #
    # Really runs it and rolls back, rather than projecting the outcome: the
    # steps feed each other -- renaming MXOX is what takes it out of the Aegis
    # group before the merge looks -- and a projection that read the table as it
    # stands would report a merge that never happens. Rollback also means the
    # attachment purges that follow a destroy never commit.
    def plan
      lines = []
      summary = {}

      Manufacturer.transaction do
        before = Manufacturer.count

        result = self.class.new(
          corrections: @corrections,
          dropped_codes: @dropped_codes,
          aliased_codes: @aliased_codes,
          logger: ->(message) { lines << message }
        ).call

        summary = {
          before:,
          after: Manufacturer.count,
          orphaned: ASSOCIATED_MODELS.sum { |model| model.where(manufacturer_id: nil).count },
          renamed: result.renamed,
          dropped: result.dropped,
          aliased: result.aliased,
          merged: result.merged
        }

        raise ActiveRecord::Rollback
      end

      summary.merge(log: lines)
    end

    # The winner keeps the row: whatever an admin curated outweighs what the
    # export can rebuild, so an rsi_id or an uploaded logo wins before row count
    # does, and age only breaks a remaining tie.
    def self.pick_winner(manufacturers)
      manufacturers.min_by do |manufacturer|
        [
          manufacturer.rsi_id.present? ? 0 : 1,
          manufacturer.logo.attached? ? 0 : 1,
          -association_count(manufacturer),
          manufacturer.created_at || Time.zone.at(0)
        ]
      end
    end

    def self.association_count(manufacturer)
      ASSOCIATED_MODELS.sum { |model| model.where(manufacturer_id: manufacturer.id).count }
    end

    private def apply_corrections
      @corrections.each do |code, name|
        manufacturer = Manufacturer.find_by(code:)

        next if manufacturer.blank? || manufacturer.name == name

        log "renaming #{code} from #{manufacturer.name.inspect} to #{name.inspect}"

        manufacturer.update!(name:)
        @result.renamed << code
      end
    end

    # Only ever removes a row nothing points at. These records are placeholders
    # the export copied from another manufacturer, but a row that somehow
    # acquired items is a row somebody is using -- it is left alone and reported
    # rather than deleted.
    private def drop_records
      Manufacturer.where(code: @dropped_codes).find_each do |manufacturer|
        count = self.class.association_count(manufacturer)

        if count.positive?
          log "keeping #{manufacturer.code}: #{count} records still point at it"
          next
        end

        log "dropping #{manufacturer.code}"

        manufacturer.destroy!
        @result.dropped << manufacturer.code
      end
    end

    # Grouped by slug rather than by name, because the table holds both kinds of
    # duplicate and the slug is the one that matters: it is what the public API
    # and the filters identify a manufacturer by, so two rows sharing one are
    # already ambiguous. Exact-name pairs ("Aegis Dynamics" four times) and the
    # spelling variants that collapse to the same slug ("Basilisk " and
    # "Basilisk", "GYSON INC" and "Gyson Inc.") both come out here.
    private def merge_collisions
      colliding_slugs.each do |slug|
        manufacturers = Manufacturer.where(slug:).to_a
        winner = self.class.pick_winner(manufacturers)

        log "#{slug}: keeping #{winner.name.inspect} " \
            "code=#{winner.code.inspect} rsi=#{winner.rsi_id.inspect} " \
            "records=#{self.class.association_count(winner)}"

        (manufacturers - [winner]).each do |loser|
          log "  merging #{loser.name.inspect} code=#{loser.code.inspect} " \
              "(#{self.class.association_count(loser)} records move across)"

          absorb(loser, winner)
        end

        normalize_name(winner)

        @result.merged << slug
      end
    end

    # The pairs no grouping finds: one company the RSI matrix and the export
    # spell differently enough that neither the code nor the slug matches --
    # "MISC" against "MIS", `misc` against `musashi-industrial-starflight-concern`.
    #
    # The pair is directed rather than scored, unlike a slug group: the target
    # code names the row that survives, so the slug the public API and every
    # saved filter already use stays put. Left to #pick_winner the export row
    # could take a pair whose curated side happens to carry no rsi_id, and the
    # manufacturer would change its public identifier as a side effect of a
    # cleanup.
    private def merge_aliases
      @aliased_codes.each do |from_code, to_code|
        loser = Manufacturer.find_by(code: from_code)

        next if loser.blank?

        winner = Manufacturer.find_by(code: to_code)

        # Reported rather than skipped quietly: a pair pointing at a code the
        # table does not carry is a stale entry, and the row it names is sitting
        # there as a duplicate in the meantime.
        if winner.blank?
          log "keeping #{from_code}: no row carries #{to_code}"
          next
        end

        next if winner == loser

        log "#{from_code} -> #{to_code}: keeping #{winner.name.inspect} " \
            "(#{self.class.association_count(loser)} records move across)"

        absorb(loser, winner)

        @result.aliased << from_code
      end
    end

    private def absorb(loser, winner)
      adopt_export_identity(loser, winner)
      repoint(loser, winner)
      loser.reload.destroy!
    end

    # The export's half of the identity moves across before the row goes, because
    # `sc_ref` is what the next sc_data load matches on: a merge that dropped it
    # would leave the export's record matching nothing, and the very next import
    # would mint the duplicate again. Everything else the load rebuilds from the
    # export -- the icon path is written on every run -- but the icon itself is
    # carried anyway so the manufacturer is not left without a picture until then.
    #
    # Only ever fills a blank, the same rule the loader follows: the winner is the
    # curated row, and what an admin put there outlives the export.
    private def adopt_export_identity(loser, winner)
      updates = {}
      updates[:sc_ref] = loser.sc_ref if winner.sc_ref.blank? && loser.sc_ref.present?
      updates[:icon_path] = loser.icon_path if winner.icon_path.blank? && loser.icon_path.present?

      winner.update!(updates) if updates.present?

      return if winner.icon.attached? || !loser.icon.attached?

      # Moved rather than re-attached from the same blob: the destroy purges what
      # the loser still holds, and two attachments sharing one blob would have it
      # delete the file the winner now points at.
      loser.icon.attachment.update!(record: winner)
    end

    # The surviving row is the curated one, which is not necessarily the one
    # spelled properly -- three of the pairs differ only by a trailing space.
    private def normalize_name(winner)
      stripped = winner.name&.strip

      return if stripped.blank? || stripped == winner.name

      log "trimming #{winner.name.inspect} to #{stripped.inspect}"

      winner.update!(name: stripped)
    end

    private def repoint(loser, winner)
      ASSOCIATED_MODELS.each do |model|
        model.where(manufacturer_id: loser.id).update_all(manufacturer_id: winner.id)
      end
    end

    private def colliding_slugs
      Manufacturer.where.not(slug: nil).group(:slug).having("count(*) > 1").count.keys
    end

    # `dependent: :nullify` on an association nobody declared does nothing, so a
    # table missing from ASSOCIATED_MODELS would lose its manufacturer silently.
    private def assert_every_association_covered!
      covered = ASSOCIATED_MODELS.map(&:table_name).to_set
      actual = Manufacturer.connection.tables.select do |table|
        Manufacturer.connection.columns(table).any? { |column| column.name == "manufacturer_id" }
      end.to_set

      missing = actual - covered

      return if missing.empty?

      raise "#{missing.to_a.sort.join(", ")} reference manufacturer_id but are not in ASSOCIATED_MODELS"
    end

    private def log(message)
      @logger&.call(message)
    end
  end
end
