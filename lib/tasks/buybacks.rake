# frozen_string_literal: true

namespace :buybacks do
  desc "List the ship names stored buy-backs give that match no model, most common first."
  task unmatched_ship_names: :environment do
    BuybackPledges::UnmatchedShipNames.new.run.each do |name, count|
      puts "#{count.to_s.rjust(6)}  #{name}"
    end
  end
end
