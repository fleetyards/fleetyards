# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FeaturesController < ::Admin::Api::BaseController
        # A flag toggled in anger still has a readable history; nobody scrolls
        # past this, and the page renders the list inline.
        HISTORY_LIMIT = 50

        before_action :set_feature, only: %i[show enable disable enable_actor disable_actor enable_group disable_group enable_percentage_of_actors enable_percentage_of_time toggle_user_self_service toggle_fleet_self_service]

        def index
          authorize! with: ::Admin::FeaturePolicy

          @features = Flipper.features.sort_by(&:name)
        end

        def show
        end

        # The rollout as it happened, newest first. Nothing else can answer "how
        # did this flag get here": flipper_gates keeps no history of its own, and
        # a boolean enable deletes the actor rows that preceded it.
        #
        # The only action that does not go through `set_feature`, because it is
        # the only one that still means something once the flag is gone: sync
        # prunes the Flipper feature and every gate with it, and `feature_name`
        # is a plain string precisely so these rows outlive that. Refusing to
        # serve them would make the retention pointless.
        def history
          authorize! with: ::Admin::FeaturePolicy

          @changes = FeatureFlagChange.for_feature(params[:id])
            .newest_first
            .includes(:admin_user, :user)
            .limit(HISTORY_LIMIT)

          # A name Flipper has never heard of and that left no rows is a typo,
          # not a pruned flag.
          not_found("Feature not found") if @changes.empty? && !flipper_knows?(params[:id])
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

        # One toggle per surface, because the two are independent. A fleet feature
        # normally wants both: the fleet switch covers every member, and the
        # personal one lets a member preview it without switching it on for the
        # rest of the fleet.
        def toggle_user_self_service
          toggle_self_service(:self_service_user)
        end

        def toggle_fleet_self_service
          toggle_self_service(:self_service_fleet)
        end

        private def toggle_self_service(column)
          setting = FeatureSetting.find_or_initialize_by(feature_name: @feature.name.to_s)
          setting[column] = !setting[column]
          setting.save!

          render :show
        end

        # Loaded once per render rather than per row -- /admin/features lists
        # every flag in the registry, and a call per flag would be ~50 queries on
        # a page with no other reason to touch this table.
        #
        # Lazy on purpose: the mutating actions all `render :show`, and the
        # summary has to describe the state they just wrote, not the one
        # set_feature saw.
        private def feature_summaries
          @feature_summaries ||= FeatureFlagChange.summaries_for(@features&.map(&:name) || [@feature.name])
        end
        helper_method :feature_summaries

        private def flipper_knows?(feature_name)
          names = Flipper.features.map(&:name)

          names.include?(feature_name.to_s) || names.include?(feature_name.to_sym)
        end

        private def set_feature
          feature_name = params[:id]
          return not_found("Feature not found") unless flipper_knows?(feature_name)

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
