# frozen_string_literal: true

require "progress_bar"

class MigrateOtpSecretToNewColumn < ActiveRecord::Migration[7.0]
  def up
    bar = ProgressBar.new(User.count)

    User.find_each do |user|
      otp_secret = user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty

      user.update!(otp_secret: otp_secret)

      bar.increment!
    end
  end

  def down
  end
end
