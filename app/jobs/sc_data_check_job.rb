# frozen_string_literal: true

class ScDataCheckJob < ApplicationJob
  def perform
    new_version = load_version_from_s3

    version_file = Rails.root.join('.sc_data_version')

    old_version = File.read(version_file).strip if File.exist?(version_file)

    return if new_version == old_version

    Loaders::ScDataShipsJob.perform_later

    File.write(version_file, new_version)
  end

  private def load_version_from_s3
    response = Typhoeus.get("#{s3_base_url}/version")

    return unless response.success?

    response.body.strip
  end

  private def s3_base_url
    [
      Rails.configuration.app.s3_endpoint,
      Rails.configuration.app.s3_sc_data_bucket
    ].join('/')
  end
end
