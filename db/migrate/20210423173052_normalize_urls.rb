class NormalizeUrls < ActiveRecord::Migration[6.1]
  def up
    User.where(homepage: 'null').update_all(homepage: nil)
    User.where(twitch: 'null').update_all(twitch: nil)
    User.where(discord: 'null').update_all(discord: nil)
    User.where(youtube: 'null').update_all(youtube: nil)
    User.where(guilded: 'null').update_all(guilded: nil)

    User.find_each do |user|
      user.update_urls(force: true)
      user.save
    end

    Fleet.where(homepage: 'null').update_all(homepage: nil)
    Fleet.where(twitch: 'null').update_all(twitch: nil)
    Fleet.where(discord: 'null').update_all(discord: nil)
    Fleet.where(youtube: 'null').update_all(youtube: nil)
    Fleet.where(guilded: 'null').update_all(guilded: nil)
    Fleet.where(ts: 'null').update_all(ts: nil)

    Fleet.find_each do |fleet|
      fleet.update_urls(force: true)
      fleet.save
    end
  end
end
