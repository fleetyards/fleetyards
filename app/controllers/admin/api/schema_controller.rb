# frozen_string_literal: true

module Admin
  module Api
    class SchemaController < ApplicationController
      def index
        authorize! :show, :admin

        not_found! unless File.exist?(Rails.root.join("api/admin-#{params[:api_version]}.yaml"))

        respond_to do |format|
          format.yaml do
            render file: Rails.root.join("api/admin-#{params[:api_version]}.yaml")
          end
        end
      end
    end
  end
end
