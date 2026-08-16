# frozen_string_literal: true

module Admin
  # Not a BasePolicy subclass on purpose: notifications are not a gated resource
  # but every admin's own inbox, so access is ownership rather than a privilege.
  class NotificationPolicy < ApplicationPolicy
    alias_rule :index?, :destroy?, :update?, :read?, :unread_count?, to: :show?

    def show?
      user.present?
    end

    def read_all?
      user.present?
    end

    def destroy_all?
      user.present?
    end

    # Ownership alone would keep a notification readable after the privilege
    # that made its owner a recipient is revoked, so the type has to be
    # re-checked against the current privileges on every read.
    relation_scope do |relation|
      relation.where(admin_user_id: user.id, notification_type: AdminNotification.types_for(user))
    end
  end
end
