# frozen_string_literal: true

class AddUserToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    add_reference :supporter_contributions, :user, type: :uuid, foreign_key: true, null: true
  end
end
