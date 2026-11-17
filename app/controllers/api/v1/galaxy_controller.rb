# frozen_string_literal: true

module Api
  module V1
    class GalaxyController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[show]

      def show
        @systems = StarSystem.order(:name)
        @tunnels = JumpTunnel.includes(:entry_system, :exit_system).order(:created_at)
      end
    end
  end
end
