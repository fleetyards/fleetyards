# frozen_string_literal: true

module Api
  module V1
    class MarkdownImagesController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create]

      skip_verify_authorized only: %i[show]

      # The address a description embeds. It names the image, not a rendition
      # of it, so the text never has to change when the rendition does, and a
      # removed image stops showing everywhere it was used.
      def show
        markdown_image = MarkdownImage.find(params[:id])

        # Briefly: a deleted image should stop showing soon, not an hour later.
        expires_in 5.minutes, public: true
        redirect_to rails_representation_url(markdown_image.display_representation), allow_other_host: true
      end

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
