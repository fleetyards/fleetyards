# frozen_string_literal: true

class ScDataCheckJob < ApplicationJob
  def perform
    new_version = load_version_from_s3

    return if new_version.blank? || Imports::ScDataImport.finished.exists?(version: new_version)

    Loaders::ScDataShipsJob.perform_async(new_version)
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
    ].join("/")
  end
end
