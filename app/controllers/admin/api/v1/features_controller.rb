# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FeaturesController < ::Admin::Api::BaseController
        before_action :set_feature, only: %i[show enable disable enable_actor disable_actor enable_group disable_group enable_percentage_of_actors enable_percentage_of_time toggle_self_service update_self_service_scope]

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

        def enable_percentage_of_actors
          percentage = params[:percentage].to_i
          unless (0..100).cover?(percentage)
            return render json: {code: "feature.invalid_percentage", message: "Percentage must be between 0 and 100"}, status: :unprocessable_entity
          end

          @feature.enable_percentage_of_actors(percentage)

          render :show
        end

        def enable_percentage_of_time
          percentage = params[:percentage].to_i
          unless (0..100).cover?(percentage)
            return render json: {code: "feature.invalid_percentage", message: "Percentage must be between 0 and 100"}, status: :unprocessable_entity
          end

          @feature.enable_percentage_of_time(percentage)

          render :show
        end

        def toggle_self_service
          setting = FeatureSetting.find_or_initialize_by(feature_name: @feature.name.to_s)
          setting.self_service = !setting.self_service
          setting.save!

          render :show
        end

        # Which surface the toggle lives on, for a flag that has one. A personal
        # toggle on a fleet-wide feature would let any member switch it on for
        # every fleet they belong to, because the backend ORs the user actor in —
        # so this is a deliberate choice per flag, not a default to fall into.
        def update_self_service_scope
          scope = params[:scope].to_s

          # Request validation rejects an out-of-enum scope before this runs, so
          # this is only here to keep an unvalidated request off the model
          # validation, which would 500 rather than say what was wrong.
          unless FeatureSetting::SELF_SERVICE_SCOPES.include?(scope)
            return render json: {
              code: "feature.invalid_self_service_scope",
              message: "Scope must be one of #{FeatureSetting::SELF_SERVICE_SCOPES.join(", ")}"
            }, status: :unprocessable_entity
          end

          setting = FeatureSetting.find_or_initialize_by(feature_name: @feature.name.to_s)
          setting.self_service_scope = scope
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
