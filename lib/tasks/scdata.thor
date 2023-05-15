# frozen_string_literal: true

require "thor"

class Scdata < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  EXPORT_FOLDER = "./data/export"

  desc "upload", "Upload exported sc data files to s3"
  def upload(sc_version = "3.19.0-PTU", dry_run = false)
    system("s3cmd sync --delete-removed#{dry_run ? " --dry-run" : ""} #{EXPORT_FOLDER}/#{sc_version}/ s3://fleetyards/sc_data/")

    system("s3cmd setacl s3://fleetyards/sc_data/ --recursive --acl-public") unless dry_run
  end
end
