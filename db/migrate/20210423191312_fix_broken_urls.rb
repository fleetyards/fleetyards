class FixBrokenUrls < ActiveRecord::Migration[6.1]
  def up
    User.find_each do |user|
      user.update_urls(force: true)
      user.save
    end

    Fleet.find_each do |fleet|
      fleet.update_urls(force: true)
      fleet.save
    end
  end
end
