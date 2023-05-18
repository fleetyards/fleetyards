# frozen_string_literal: true

module Admin
  module Api
    class SchemaController < ApplicationController
      def index
        authorize! :show, :admin

        not_found! unless File.exist?(Rails.root.join("swagger/admin/#{params[:api_version]}/schema.yaml"))

        respond_to do |format|
          format.yaml do
            render file: Rails.root.join("swagger/admin/#{params[:api_version]}/schema.yaml")
          end
        end
      end
    end
  end
end
