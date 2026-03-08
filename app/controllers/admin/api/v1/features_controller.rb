# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FeaturesController < ::Admin::Api::BaseController
        before_action :set_feature, only: %i[show enable disable enable_actor disable_actor enable_group disable_group toggle_self_service]

        def index
          authorize! with: ::Admin::FeaturePolicy

          @features = Flipper.features.sort_by(&:name)
        end

        def show
        end

        def enable
          @feature.enable

          render :show
        end

        def disable
          @feature.disable

          render :show
        end

        def enable_actor
          actor = find_actor
          return not_found(I18n.t("messages.record_not_found.base")) unless actor

          @feature.enable_actor(actor)

          render :show
        end

        def disable_actor
          actor = find_actor
          return not_found(I18n.t("messages.record_not_found.base")) unless actor

          @feature.disable_actor(actor)

          render :show
        end

        def enable_group
          group_name = params[:group]
          return not_found("Group not found") unless Flipper.group_exists?(group_name)

          @feature.enable_group(group_name)

          render :show
        end

        def disable_group
          group_name = params[:group]
          return not_found("Group not found") unless Flipper.group_exists?(group_name)

          @feature.disable_group(group_name)

          render :show
        end

        def toggle_self_service
          setting = FeatureSetting.find_or_initialize_by(feature_name: @feature.name.to_s)
          setting.self_service = !setting.self_service
          setting.save!

          render :show
        end

        private def set_feature
          feature_name = params[:id]
          unless Flipper.features.map(&:name).include?(feature_name.to_s) || Flipper.features.map(&:name).include?(feature_name.to_sym)
            return not_found("Feature not found")
          end

          @feature = Flipper.feature(feature_name)

          authorize! @feature, with: ::Admin::FeaturePolicy
        end

        private def find_actor
          case params[:actor_type]
          when "User"
            User.find_by(id: params[:actor_id]) || User.find_by(username: params[:actor_id])
          when "Fleet"
            Fleet.find_by(id: params[:actor_id]) || Fleet.find_by(fid: params[:actor_id])
          end
        end
      end
    end
  end
end
