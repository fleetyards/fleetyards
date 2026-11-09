# frozen_string_literal: true

module Api
  module V1
    class CharacterBodiesController < ::Api::PublicBaseController
      include DressingRoomFeatureConcern

      skip_verify_authorized only: %i[index]

      before_action :check_dressing_room_feature

      def index
        @character_bodies = CharacterBody.with_holo
        @default_eyes = default_eyes
      end

      # Without the customizer export the bodies are still served, eyes as
      # textured.
      private def default_eyes
        ::Chf::Context.current&.default_eyes
      rescue => e
        Rails.logger.error("[chf] default eyes could not be read: #{e.class}: #{e.message}")
        nil
      end
    end
  end
end
