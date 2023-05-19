# frozen_string_literal: true

module Api
  class DocsController < ApplicationController
    def v1
      @title = I18n.t("title.api.docs.v1")

      schema_file = Rails.root.join("#{schema_folder}/v1/schema.yaml")

      not_found! unless File.exist?(schema_file)

      respond_to do |format|
        format.html do
          render_docs(YAML.load_file(schema_file))
        end
      end
    end

    def swagger
      @title = I18n.t("title.api.docs.swagger")

      @config = {
        urls: [{
          url: "v1/schema.yaml",
          name: "V1"
        }]
      }

      respond_to do |format|
        format.html do
          render "swagger_ui/index", layout: false
        end
      end
    end

    private def render_docs(schema)
      @paths = schema["paths"].map do |path, options|
        options.keys.filter_map do |method|
          next unless options[method].is_a?(Hash)

          {
            path: path,
            parameters: options[method]["parameters"],
            name: options[method]["summary"],
            method: method,
            description: options[method]["description"],
            responses: options[method]["responses"],
            tags: options[method]["tags"]
          }
        end
      end.flatten

      @tags = @paths.pluck(:tags).flatten.uniq

      @models = schema.dig("components", "schemas")

      render "index", layout: "api/docs"
    end

    private def api_version
      @api_version ||= params[:api_version].downcase
    end

    private def schema_folder
      Rails.configuration.api_schema.folder
    end
  end
end
