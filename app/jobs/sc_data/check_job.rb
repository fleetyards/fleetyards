# frozen_string_literal: true

module ScData
  class CheckJob < ApplicationJob
    def perform
      new_version = Rails.configuration.sc_data[:version]

      return if new_version.blank? || Imports::ScData::AllImport.finished.exists?(version: new_version)

      Loaders::ScData::AllJob.perform_async(new_version)
    end
  end
end
