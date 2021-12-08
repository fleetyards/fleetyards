# frozen_string_literal: true

require 'thor'
require 'fileutils'

class Fleetchart < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'prepare', 'Prepare export folder for upload or local import'
  def prepare(export_folder)
    export_path = "#{export_folder}/export"
    seeds_path = "#{export_folder}/seeds_fleetchart"

    run("mkdir -p \"#{seeds_path}\"")

    Dir["#{export_path}/**/*.png"].each do |file|
      name = File.basename(file)

      next unless name.include?('fleetchart')

      dir_name = File.basename(File.dirname(file))
      dir = "#{seeds_path}/#{dir_name}"

      run("mkdir -p \"#{dir}\"")

      FileUtils.cp(file, "#{dir}/#{name}")
    end

    Dir["#{export_path}/**/*.gltf"].each do |file|
      name = File.basename(file)
      dir_name = File.basename(File.dirname(file))
      dir = "#{seeds_path}/#{dir_name}"

      run("mkdir -p \"#{dir}\"")

      FileUtils.cp(file, "#{dir}/#{name}")
    end
  end

  desc 'local_import', 'Import prepared seeds'
  def local_import(export_folder)
    require './config/environment'

    seeds_path = "#{export_folder}/seeds_fleetchart"

    FileUtils.cp_r(seeds_path, Rails.root.join('db/'))
  end

  desc 'upload', 'Upload prepared seeds to server'
  def upload(export_folder, environment = 'stage')
    seeds_path = "#{export_folder}/seeds_fleetchart/"

    run("scp -r \"#{seeds_path}\" fleetyards@fleetyards.net:~/shared/db") if environment == 'live'

    run("scp -r \"#{seeds_path}\" fleetyards@stage.fleetyards.net:~/shared/db") if environment == 'stage'
  end
end
