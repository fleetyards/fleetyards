# frozen_string_literal: true

module Api
  module V1
    # A character as a share link shows it: the token is the whole of the
    # access, so anyone holding it sees the character and can download the
    # file.
    class SharedCharacterFacesController < ::Api::PublicBaseController
      include DressingRoomFeatureConcern

      skip_verify_authorized only: %i[show]

      before_action :check_dressing_room_feature

      def show
        @character_face = CharacterFace.with_attached_chf.find_by!(token: params[:token])
      end
    end
  end
end
