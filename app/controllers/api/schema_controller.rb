# frozen_string_literal: true

module Api
  class SchemaController < ApplicationController
    def index
      not_found! unless File.exist?(Rails.root.join("swagger/#{params[:api_version]}/schema.yaml"))

      render file: Rails.root.join("swagger/#{params[:api_version]}/schema.yaml")
    end
  end
end
