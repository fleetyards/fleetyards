# frozen_string_literal: true

module Api
  module V1
    class CharacterFacesController < ::Api::BaseController
      include DressingRoomFeatureConcern

      READ_ACTIONS = %i[index].freeze

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: READ_ACTIONS
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: READ_ACTIONS

      before_action :check_dressing_room_feature
      before_action :set_character_face, only: %i[update destroy]

      def index
        authorize! with: CharacterFacePolicy

        @character_faces = authorized_scope(CharacterFace.all, with: CharacterFacePolicy).with_attached_chf.order(:name)
      end

      def create
        @character_face = current_resource_owner.character_faces.new(
          name: params[:name].presence,
          expected_body: params[:body].presence
        )
        @character_face.file = params.require(:file)

        authorize! @character_face, with: CharacterFacePolicy

        if save_character_face
          render :show, status: :created
        else
          render json: ValidationError.new("character_faces.create", errors: @character_face.errors), status: :bad_request
        end
      end

      def update
        @character_face.name = params.require(:name)

        if save_character_face
          render :show
        else
          render json: ValidationError.new("character_faces.update", errors: @character_face.errors), status: :bad_request
        end
      end

      def destroy
        @character_face.destroy!

        render json: {success: true}
      end

      private def save_character_face
        @character_face.save
      rescue ActiveRecord::RecordNotUnique
        @character_face.errors.add(:name, :taken)
        false
      end

      private def set_character_face
        @character_face = authorized_scope(CharacterFace.all, with: CharacterFacePolicy).find(params[:id])

        authorize! @character_face, to: :manage?, with: CharacterFacePolicy
      end
    end
  end
end
