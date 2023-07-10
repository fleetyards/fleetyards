# frozen_string_literal: true

module Api
  class DocsController < ApplicationController
    def index
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
  end
end
