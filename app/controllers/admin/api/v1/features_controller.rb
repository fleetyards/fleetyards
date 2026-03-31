# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FeaturesController < ::Admin::Api::BaseController
        before_action :set_feature, only: %i[show enable disable enable_actor disable_actor enable_group disable_group toggle_self_service destroy]

        def index
          authorize! with: ::Admin::FeaturePolicy

          @features = Flipper.features.sort_by(&:name)
        end

        def show
        end

        def create
          authorize! with: ::Admin::FeaturePolicy

          feature_name = params[:name].to_s.strip
          return render json: {code: "feature.blank", message: "Feature name can't be blank"}, status: :unprocessable_entity if feature_name.blank?

          if Flipper.features.map { |f| f.name.to_s }.include?(feature_name)
            return render json: {code: "feature.exists", message: "Feature already exists"}, status: :unprocessable_entity
          end

          @feature = Flipper.feature(feature_name)
          @feature.add

          render :show, status: :created
        end

        def destroy
          FeatureSetting.find_by(feature_name: @feature.name.to_s)&.destroy
          @feature.remove

          head :no_content
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
