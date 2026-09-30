# frozen_string_literal: true

module Api
  module V1
    class MarkdownImagesController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      def create
        @markdown_image = MarkdownImage.new(user: current_resource_owner)

        authorize! @markdown_image

        @markdown_image.assign_attributes(authorized(params, with: MarkdownImagePolicy))

        if @markdown_image.save
          render status: :created
        else
          render json: ValidationError.new("markdown_image.create", errors: @markdown_image.errors), status: :bad_request
        end
      end
    end
  end
end
