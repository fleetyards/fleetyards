# frozen_string_literal: true

module Admin
  module Api
    module V1
      class EquipmentController < ::Admin::Api::BaseController
        def weapons
          authorize! :index, :admin_api_equipment

          @equipment = Equipment.where(equipment_type: :weapon).all
        end

        def attachments
          authorize! :index, :admin_api_equipment

          @equipment = Equipment.where(equipment_type: :weapon_attachment).all
        end

        def utilities
          authorize! :index, :admin_api_equipment

          @equipment = Equipment.where(equipment_type: :medical).all
        end
      end
    end
  end
end
