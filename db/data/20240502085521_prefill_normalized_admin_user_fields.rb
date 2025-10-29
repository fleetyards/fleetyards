# frozen_string_literal: true

class PrefillNormalizedAdminUserFields < ActiveRecord::Migration[7.1]
  def up
    AdminUser.find_each do |admin_user|
      admin_user.set_normalized_login_fields
      admin_user.save!
    end
  end
end
