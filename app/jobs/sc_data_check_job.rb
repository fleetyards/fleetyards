# frozen_string_literal: true

class ScDataCheckJob < ApplicationJob
  def perform
    new_version = File.read(Rails.public_path.join('sc_data/.version')).strip

    version_file = Rails.root.join('.sc_data_version')

    old_version = File.read(version_file).strip if File.exist?(version_file)

    return if new_version == old_version

    Loaders::ScDataShipsJob.perform_later

    File.write(version_file, new_version)
  end
end
