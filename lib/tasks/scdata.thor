# frozen_string_literal: true

require "thor"

class Scdata < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  EXPORT_FOLDER = "data/sc_data"

  desc "setup", "Setup sc data export symlink"
  def setup(source_folder, export_folder = EXPORT_FOLDER)
    say("Creating symlink from #{source_folder} to #{export_folder}/raw", :green)
    system("ln -s #{source_folder} #{export_folder}/raw")
  end

  desc "parse", "Parse SC Data"
  def parse(sc_version = nil, sc_environment = nil, export_folder = EXPORT_FOLDER)
    require "./config/environment"

    sc_version ||= Rails.configuration.app.sc_data[:version]
    sc_environment ||= Rails.configuration.app.sc_data[:environment]

    ScData::Parser::BaseParser.all(base_folder: Rails.root.join(export_folder), sc_version:, sc_environment:)
  end

  desc "load_items", "Load Items from SC Data"
  def load_items(sc_version = nil, sc_environment = nil, export_folder = EXPORT_FOLDER)
    require "./config/environment"

    sc_version ||= Rails.configuration.app.sc_data[:version]
    sc_environment ||= Rails.configuration.app.sc_data[:environment]

    ScData::Loader::ItemsLoader.new(sc_version:, sc_environment:).all
  end
end
