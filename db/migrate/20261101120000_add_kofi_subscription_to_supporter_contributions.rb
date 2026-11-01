# frozen_string_literal: true

class AddKofiSubscriptionToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    add_column :supporter_contributions, :kofi_subscription, :boolean, default: false, null: false
  end
end
