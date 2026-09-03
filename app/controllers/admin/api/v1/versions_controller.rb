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

        # What the other admins changed while you were away.
        #
        # Scoped by item type rather than record by record: the per-record `index`
        # can walk one item to its authorisation root, but a feed cannot do that
        # for every row it returns.
        #
        # These three are the types that record *who* made the change -- they map
        # `author_id` through paper_trail's `meta:`. Component is deliberately
        # absent: it is versioned, but carries no `author_id` accessor, so a
        # component edit is unattributed and would join the feed as an anonymous
        # row. Worth closing separately; it is a gap in Component, not here.
        FEED_ACCESS_BY_ITEM_TYPE = {
          "Model" => :models,
          "ModelModule" => :model_modules,
          "Fleet" => :fleets
        }.freeze

        def recent
          authorize! with: ::Admin::VersionFeedPolicy

          item_types = FEED_ACCESS_BY_ITEM_TYPE
            .select { |_type, access| current_user.has_access?([access]) }
            .keys

          @versions = PaperTrail::Version
            .where(item_type: item_types)
            .where.not(author_id: nil)
            # A `touch` files a version with no changeset -- Fleet alone holds
            # 572,735 of them against 464 real edits -- and they render as a
            # heading with nothing under it.
            .where.not(object_changes: nil)
            .order(created_at: :desc)
            .page(params[:page])
            .per(params[:per_page] || params[:perPage] || 10)

          @authors = AdminUser.where(id: @versions.filter_map(&:author_id).uniq).index_by(&:id)
          @item_names = item_names_for(@versions)

          render :index
        end

        # "Model" alone does not say which ship was edited, and the feed is
        # unreadable without it. One query per type present on the page rather
        # than one per row -- and a name may be missing, because a version
        # outlives the record it describes.
        private def item_names_for(versions)
          versions.group_by(&:item_type).each_with_object({}) do |(item_type, rows), names|
            next unless FEED_ACCESS_BY_ITEM_TYPE.key?(item_type)

            item_type.constantize
              .where(id: rows.map(&:item_id))
              .pluck(:id, :name)
              .each { |id, name| names[[item_type, id]] = name }
          end
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
