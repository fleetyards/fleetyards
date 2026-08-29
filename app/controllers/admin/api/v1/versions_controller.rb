# frozen_string_literal: true

module Admin
  module Api
    module V1
      class VersionsController < ::Admin::Api::BaseController
        before_action :set_version, only: %i[revert]

        def index
          item = ::VersionedItem.find(params[:item_type] || params[:itemType], params[:item_id] || params[:itemId])

          authorize_item!(item)

          # The touch versions already on disk outnumber the real edits 1,200 to
          # one on a fleet, and each renders as a heading with nothing under it.
          # `object_changes` is null on exactly those: every create, update and
          # destroy paper_trail records from a save carries one.
          @versions = PaperTrail::Version
            .where(item_type: item.class.name, item_id: item.id)
            .where.not(object_changes: nil)
            .order(created_at: :desc)
            .page(params[:page])
            .per(params[:per_page] || params[:perPage])

          # `author_id` is only ever written by an admin action, so one lookup
          # covers the page rather than one per row.
          @authors = AdminUser.where(id: @versions.filter_map(&:author_id).uniq).index_by(&:id)
        end

        def revert
          result = ::Versions::FieldReverter.new(@version, params[:field].to_s, author_id: current_user.id).run

          raise ActiveRecord::RecordNotFound if result.missing?

          unless result.success?
            render json: ValidationError.new("version.revert", errors: result.record.errors), status: :bad_request
            return
          end

          head :no_content
        end

        private def set_version
          @version = PaperTrail::Version.find(params[:id])

          raise ActiveRecord::RecordNotFound unless ::VersionedItem.supported?(@version.item_type)

          authorize_item!(@version.item)
        end

        # The item carries the permission, not the version: whoever may see a
        # model may see what it used to say.
        private def authorize_item!(item)
          raise ActiveRecord::RecordNotFound if item.blank?

          root, policy = ::VersionedItem.authorization_root(item)

          raise ActiveRecord::RecordNotFound if root.blank?

          authorize! root, with: policy
        end
      end
    end
  end
end
