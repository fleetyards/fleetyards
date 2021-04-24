class PrefillNotificationChannels < ActiveRecord::Migration[6.1]
  def up
    User.where(sale_notify: true).find_each do |user|
      NotificationChannel.create(user_id: user.id, channel: :email, confirmed: user.confirmed_at.present?)
    end
  end
end
