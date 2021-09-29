# frozen_string_literal: true

module Api
  class SchemaController < ApplicationController
    def index
      not_found! unless File.exist?(Rails.root.join("api/#{params[:api_version]}.yaml"))

      render file: Rails.root.join("api/#{params[:api_version]}.yaml")
    end
  end
end
