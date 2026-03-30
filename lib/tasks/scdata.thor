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
  def parse(sc_environment = nil, export_folder = EXPORT_FOLDER)
    require "./config/environment"

    sc_environment ||= Rails.configuration.sc_data[:environment]
    sc_version = latest_version(export_folder, sc_environment)

    say("Parsing SC Data version: #{sc_version} (#{sc_environment})", :green)

    ScData::Parser::BaseParser.all(base_folder: Rails.root.join(export_folder), sc_version:, sc_environment:)

    update_config(sc_version, sc_environment)

    say("Updated config/app/sc_data.yml to version: #{sc_version}", :green)
  end

  desc "load_all", "Load all SC Data (manufacturers, items, models, model modules)"
  def load_all
    require "./config/environment"

    say("Loading all SC Data #{config_info}", :green)

    ScData::Loader::BaseLoader.all
  end

  desc "load_manufacturers", "Load Manufacturers from SC Data"
  def load_manufacturers
    require "./config/environment"

    say("Loading manufacturers from SC Data #{config_info}", :green)

    ScData::Loader::ManufacturersLoader.new.all
  end

  desc "load_items", "Load Items from SC Data"
  def load_items
    require "./config/environment"

    say("Loading items from SC Data #{config_info}", :green)

    ScData::Loader::ItemsLoader.new.all
  end

  desc "load_models", "Load Models (hardpoints) from SC Data"
  def load_models
    require "./config/environment"

    say("Loading models from SC Data #{config_info}", :green)

    ScData::Loader::ModelsLoader.new.all
  end

  desc "load_model_modules", "Load Model Modules from SC Data"
  def load_model_modules
    require "./config/environment"

    say("Loading model modules from SC Data #{config_info}", :green)

    ScData::Loader::ModelModulesLoader.new.all
  end

  private

  def config_info
    config = Rails.configuration.sc_data
    "version: #{config[:version]} (#{config[:environment]})"
  end

  def latest_version(export_folder, sc_environment)
    raw_path = File.join(export_folder, "raw")

    raise Thor::Error, "Raw data folder not found: #{raw_path}" unless Dir.exist?(raw_path)

    folders = Dir.children(raw_path)
      .select { |name| name.match?(/\A.+-#{Regexp.escape(sc_environment)}\.\d+\z/) }
      .sort_by { |name| name.match(/\.(\d+)\z/)[1].to_i }

    raise Thor::Error, "No data found for environment: #{sc_environment}" if folders.empty?

    folders.last
  end

  def update_config(sc_version, sc_environment)
    config_path = File.join(Dir.pwd, "config/app/sc_data.yml")

    content = <<~YAML
      shared:
        version: "#{sc_version}"
        environment: "#{sc_environment}"
    YAML

    File.write(config_path, content)
  end
end
