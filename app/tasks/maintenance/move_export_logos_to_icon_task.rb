# frozen_string_literal: true

module Maintenance
  # Undoes the loads that wrote the export's artwork into `logo`, back when the
  # sc_data loader had no `icon` attachment of its own to write to. Those runs
  # replaced the curated logo -- an admin's upload, or RSI's own artwork -- on
  # every pass.
  #
  # The blob is moved, not re-fetched and not purged: the attachment is pointed
  # at `icon` and only then dropped from `logo`, so the file is never deleted
  # and the site keeps showing the same picture throughout. A `logo` left empty
  # is what lets `Rsi::ManufacturersLoader` fill the real one back in, since it
  # only attaches while nothing is there.
  #
  # Identified by comparing the attached blob against the artwork the parsed
  # tree holds for the record's `icon_path` -- the same checksum the loader
  # itself compares -- so a logo somebody uploaded by hand is never mistaken
  # for one of ours, whatever it is named.
  class MoveExportLogosToIconTask < MaintenanceTasks::Task
    no_collection

    # Left on by default so an accidental run reports instead of moving.
    attribute :dry_run, :boolean, default: true

    def process
      moved = []
      skipped_no_art = []
      kept = []

      Manufacturer.joins(:logo_attachment).includes(logo_attachment: :blob).find_each do |manufacturer|
        file = parsed_icon(manufacturer.icon_path)

        if file.blank?
          skipped_no_art << manufacturer.code
          next
        end

        unless Digest::MD5.file(file).base64digest == manufacturer.logo.blob.checksum
          kept << manufacturer.code
          next
        end

        move(manufacturer) unless dry_run
        moved << manufacturer.code
      end

      log "export artwork found in `logo`: #{moved.size}"
      log "curated logos left alone: #{kept.size}"
      log "logos whose record names no export artwork, left alone: #{skipped_no_art.size}"
      log "moved: #{moved.sort.join(", ")}" if moved.any?
      log dry_run ? "dry run -- nothing was changed" : "moved to `icon`, `logo` is free for RSI to refill"
    end

    # Ordered so the blob is never left unreferenced: `icon` takes it first, and
    # `logo` gives it up only afterwards. `detach` drops the attachment without
    # purging, which `purge` would do -- and the bucket has no versioning, so a
    # purge here would be the same data loss this task exists to undo.
    private def move(manufacturer)
      blob = manufacturer.logo.blob

      manufacturer.icon.attach(blob) unless manufacturer.icon.attached?
      manufacturer.logo.detach
    end

    private def parsed_icon(icon_path)
      return if icon_path.blank?

      Dir.glob(
        Rails.root.join("data/sc_data/parsed/#{sc_environment}/icons/#{icon_path.sub(/\.\w+\z/, "")}.*")
      ).first
    end

    private def sc_environment
      Rails.configuration.sc_data[:environment]
    end

    # The task's log is its output in the UI, which is stdout for this engine.
    private def log(message)
      puts message
    end
  end
end
