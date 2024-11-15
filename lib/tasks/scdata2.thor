# frozen_string_literal: true

require "thor"

class Scdata2 < Thor
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

  desc "parse", "Parse sc data files"
  def parse(sc_version = "4.0.0-EPTU", export_folder = EXPORT_FOLDER)
    require "./config/environment"

    ScData::Parser.new(base_folder: EXPORT_FOLDER, version: sc_version).run
  end

  desc "upload", "Upload exported sc data files to s3"
  def upload(sc_version = "4.0.0-EPTU", export_folder = EXPORT_FOLDER, dry_run = false)
    system("s3cmd sync --delete-removed#{dry_run ? " --dry-run" : ""} #{EXPORT_FOLDER}/#{sc_version}/ s3://fleetyards/sc_data/")

    system("s3cmd setacl s3://fleetyards/sc_data/ --recursive --acl-public") unless dry_run
  end
end
