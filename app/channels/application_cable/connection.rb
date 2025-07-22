# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_admin_user

    def connect
      self.current_user = find_verified_user
      self.current_admin_user = find_verified_admin_user
    end

    protected def find_verified_user
      env["warden"].user(:user)
    end

    protected def find_verified_admin_user
      env["warden"].user(:admin_user)
    end
  end
end
