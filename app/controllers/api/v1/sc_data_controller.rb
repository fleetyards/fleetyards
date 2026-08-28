# frozen_string_literal: true

module Api
  module V1
    class ScDataController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []

      def current_version
        render json: {version: Imports::ScData::AllImport.current_version}, status: :ok
      end

      # Which builds a reader may be pointed at, for the source switch to be
      # built from. Only sources a catalogue carries builds for: an environment
      # nothing has loaded would answer every question with nothing.
      def sources
        @sources = ::ScData::Source.available
      end
    end
  end
end
