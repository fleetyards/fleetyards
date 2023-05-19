# frozen_string_literal: true

module Api
  class SchemaController < ApplicationController
    def index
      not_found! unless File.exist?(Rails.root.join("#{schema_folder}/#{params[:api_version]}/schema.yaml"))

      render file: Rails.root.join("#{schema_folder}/#{params[:api_version]}/schema.yaml")
    end

    private def schema_folder
      Rails.configuration.api_schema.folder
    end
  end
end
