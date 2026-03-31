# frozen_string_literal: true

module Oauth
  class SchemaController < ActionController::API
    def index
      return head(:not_found) unless File.exist?(Rails.root.join("swagger/oauth/#{params[:api_version]}/schema.yaml"))

      render file: Rails.root.join("swagger/oauth/#{params[:api_version]}/schema.yaml")
    end
  end
end
