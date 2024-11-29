# frozen_string_literal: true

require "thor"

class Scdata < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  EXPORT_FOLDER = "data/sc_data"
  SC_VERSION = "4.0.0-PTU"

  desc "setup", "Setup sc data export symlink"
  def setup(source_folder, export_folder = EXPORT_FOLDER)
    say("Creating symlink from #{source_folder} to #{export_folder}/raw", :green)
    system("ln -s #{source_folder} #{export_folder}/raw")
  end

  desc "parse", "Parse SC Data"
  def parse(sc_version = SC_VERSION, export_folder = EXPORT_FOLDER)
    require "./config/environment"

    ScData::Parser::BaseParser.run_all(base_folder: Rails.root.join(export_folder), sc_version:)
  end

  desc "load_items", "Load Items from SC Data"
  def load_items(sc_version = SC_VERSION, export_folder = EXPORT_FOLDER)
    require "./config/environment"

    ScData::Loader::ItemsLoader.new(sc_version:).run
  end
end
