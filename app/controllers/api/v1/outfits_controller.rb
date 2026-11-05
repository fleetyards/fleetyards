# frozen_string_literal: true

module Api
  module V1
    class OutfitsController < ::Api::BaseController
      include DressingRoomFeatureConcern

      READ_ACTIONS = %i[index show].freeze

      EQUIPMENT_PRELOAD = [
        :manufacturer, :build, ItemViews::DISPLAY_IMAGE_PRELOAD, {item_prices: ItemPrice::SHOP_LINK}
      ].freeze

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: READ_ACTIONS
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: READ_ACTIONS

      before_action :check_dressing_room_feature
      before_action :set_outfit, except: %i[index create]

      def index
        authorize! with: OutfitPolicy

        @outfits = authorized_scope(Outfit.all, with: OutfitPolicy)
          .includes(items: {equipment: EQUIPMENT_PRELOAD}, stored_items: {equipment: EQUIPMENT_PRELOAD})
          .order(:name)
      end

      def show
      end

      def create
        @outfit = current_resource_owner.outfits.new(outfit_params)

        authorize! @outfit, with: OutfitPolicy

        if save_outfit
          render :show, status: :created
        else
          render json: ValidationError.new("outfits.create", errors: @outfit.errors), status: :bad_request
        end
      end

      def update
        @outfit.assign_attributes(outfit_params)

        if save_outfit
          render :show
        else
          render json: ValidationError.new("outfits.update", errors: @outfit.errors), status: :bad_request
        end
      end

      def destroy
        @outfit.destroy!

        render json: {success: true}
      end

      # Two saves at once both pass the uniqueness checks; the indexes refuse
      # the second, which is the same answer: a name taken, or a slot filled.
      private def save_outfit
        @outfit.save
      rescue ActiveRecord::RecordNotUnique => e
        @outfit.errors.add(e.message.include?("index_outfits_on_user_id_and_name") ? :name : :items, :taken)
        false
      end

      private def set_outfit
        @outfit = authorized_scope(Outfit.all, with: OutfitPolicy)
          .includes(items: {equipment: EQUIPMENT_PRELOAD}, stored_items: {equipment: EQUIPMENT_PRELOAD})
          .find(params[:id])

        authorize! @outfit, to: :show?, with: OutfitPolicy
      end

      private def outfit_params
        permitted = params.transform_keys(&:underscore).permit(
          :name, :held_weapon, :body,
          items: %i[slot equipment_id],
          stored_items: %i[holder equipment_id quantity]
        )
        items = permitted.delete(:items)
        stored_items = permitted.delete(:stored_items)

        permitted.merge({item_list: items, stored_item_list: stored_items}.compact)
      end
    end
  end
end
