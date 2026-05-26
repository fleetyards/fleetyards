# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ImportsController < ::Admin::Api::BaseController
        before_action :set_import, only: [:show]

        def index
          authorize! with: ::Admin::ImportPolicy

          imports_query_params["sorts"] = "created_at desc"

          scope = apply_requester_filter(authorized_scope(Import.all))

          @q = scope.ransack(imports_query_params)

          @imports = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def show
        end

        private def imports_query_params
          @imports_query_params ||= params.permit(q: [
            :type_eq, :aasm_state_eq, :include_system, type_in: [], type_not_in: [],
                                                       aasm_state_in: [], admin_user_username_in: [], user_username_in: []
          ]).fetch(:q, {})
        end

        private def apply_requester_filter(scope)
          admin_usernames = imports_query_params.delete("admin_user_username_in")
          user_usernames = imports_query_params.delete("user_username_in")
          include_system = ActiveModel::Type::Boolean.new.cast(
            imports_query_params.delete("include_system")
          )

          return scope unless admin_usernames.present? || user_usernames.present? || include_system

          import_table = Import.arel_table
          clauses = []

          if admin_usernames.present?
            clauses << import_table[:admin_user_id].in(
              AdminUser.where(username: admin_usernames).select(:id).arel
            )
          end

          if user_usernames.present?
            clauses << import_table[:user_id].in(
              User.where(username: user_usernames).select(:id).arel
            )
          end

          if include_system
            clauses << import_table[:admin_user_id].eq(nil).and(import_table[:user_id].eq(nil))
          end

          scope.where(clauses.reduce { |memo, clause| memo.or(clause) })
        end

        private def set_import
          @import = Import.find(params[:id])

          authorize! @import, with: ::Admin::ImportPolicy
        end
      end
    end
  end
end
