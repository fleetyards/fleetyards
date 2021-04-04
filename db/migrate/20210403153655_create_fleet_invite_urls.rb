class CreateFleetInviteUrls < ActiveRecord::Migration[6.1]
  def change
    create_table :fleet_invite_urls, id: :uuid do |t|
      t.uuid :fleet_id
      t.uuid :user_id
      t.string :token

      t.timestamps
    end
  end
end
