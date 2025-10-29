# frozen_string_literal: true

require "thor"

class Scdata < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  EXPORT_FOLDER = "./data/export"

  desc "setup", "Setup sc data export symlink"
  def setup(source_folder, export_folder = EXPORT_FOLDER)
    say("Creating symlink from #{source_folder} to #{export_folder}", :green)
    system("ln -s #{source_folder} #{export_folder}")
  end

  desc "upload", "Upload exported sc data files to s3"
  def upload(sc_version = "3.23.1-PTU", export_folder = EXPORT_FOLDER, dry_run = false)
    system("s3cmd sync --delete-removed#{" --dry-run" if dry_run} #{EXPORT_FOLDER}/#{sc_version}/ s3://fleetyards/sc_data/")

    system("s3cmd setacl s3://fleetyards/sc_data/ --recursive --acl-public") unless dry_run
  end
end
