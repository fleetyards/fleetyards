# frozen_string_literal: true

require "thor"

class Uploads < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  S3_BUCKET = "fleetyards/uploads"
  EXPORT_FOLDER = "./public/uploads"

  desc "sync_to_local", "Sync Uploads from S3"
  def sync_to_local(dry_run = false)
    system("s3cmd sync --delete-removed#{" --dry-run" if dry_run} s3://#{S3_BUCKET} #{EXPORT_FOLDER}")
  end
end
